require 'spec_helper'

describe CarrierWave::Downloader::Base do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:file) { File.read(file_path("test.jpg")) }
  let(:filename) { "test.jpg" }
  let(:uri) { URI.encode("http://www.example.com/#{filename}") }

  subject { CarrierWave::Downloader::Base.new(uploader) }

  context "with unicode sybmols in URL" do
    let(:filename) { "юникод.jpg" }
    before do
      stub_request(:get, uri).to_return(body: file)
    end

    let(:remote_file) { subject.download(uri) }

    it "downloads a file" do
      expect(remote_file).to be_an_instance_of(CarrierWave::Downloader::RemoteFile)
    end

    it "sets the filename to the file's decoded sanitized filename" do
      expect(remote_file.original_filename).to eq("#{filename}")
    end
  end

  context "with a URL with internationalized domain name" do
    let(:uri) { URI.encode("http://ドメイン名例.jp/#{filename}") }
    before do
      stub_request(:get, 'http://xn--eckwd4c7cu47r2wf.jp/test.jpg').to_return(body: file)
    end

    it "converts to Punycode URI" do
      expect(subject.process_uri(uri).to_s).to eq 'http://xn--eckwd4c7cu47r2wf.jp/test.jpg'
    end

    it "downloads a file" do
      expect(subject.download(uri).file.read).to eq file
    end
  end

  context 'with request headers' do
    let(:authentication_headers) do
      {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent'=>"CarrierWave/#{CarrierWave::VERSION}",
        'Authorization'=>'Bearer QWE'
      }
    end
    before do
      stub_request(:get, uri).
        with(:headers => authentication_headers).
        to_return(body: file)
    end

    it 'pass custom headers to request' do
      expect(subject.download(uri, { 'Authorization' => 'Bearer QWE' }).file.read).to eq file
    end
  end

  it "raises an error when trying to download a local file" do
    expect { subject.download('/etc/passwd') }.to raise_error(CarrierWave::DownloadError)
  end

  context "with missing file" do
    before do
      stub_request(:get, uri).to_return(status: 404)
    end

    it "raises an error when trying to download a missing file" do
      expect{ subject.download(uri) }.to raise_error(CarrierWave::DownloadError)
    end

    it "doesn't obscure original exception message" do
      expect { subject.download(uri) }.to raise_error(CarrierWave::DownloadError, /could not download file: 404/)
    end
  end

  context "with a url that contains space" do
    let(:filename) { "my test.jpg" }
    before do
      stub_request(:get, uri).to_return(body: file)
    end

    it "accepts spaces in the url" do
      expect(subject.download(uri).original_filename).to eq filename
    end
  end

  context "with redirects" do
    let(:another_uri) { 'http://example.com/redirected.jpg' }
    before do
      stub_request(:get, uri).
        to_return(status: 301, body: "Redirecting", headers: { "Location" => another_uri })
      stub_request(:get, another_uri).to_return(body: file)
    end

    it "retrieves redirected file" do
      expect(subject.download(uri).file.read).to eq file
    end

    it "extracts filename from the url after redirection" do
      expect(subject.download(uri).original_filename).to eq 'redirected.jpg'
    end
  end

  describe '#process_uri' do
    it "parses but not escape already escaped uris" do
      uri = 'http://example.com/%5B.jpg'
      processed = subject.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq(uri)
    end

    it "parses but not escape uris with query-string-only characters not needing escaping" do
      uri = 'http://example.com/?foo[]=bar'
      processed = subject.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq(uri)
    end

    it "escapes and parse unescaped uris" do
      uri = 'http://example.com/ %[].jpg'
      processed = subject.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq('http://example.com/%20%25%5B%5D.jpg')
    end

    it "escapes and parse brackets in uri paths without harming the query string" do
      uri = 'http://example.com/].jpg?test[]'
      processed = subject.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq('http://example.com/%5D.jpg?test[]')
    end

    it "throws an exception on bad uris" do
      uri = '~http:'
      expect { subject.process_uri(uri) }.to raise_error(CarrierWave::DownloadError)
    end
  end
end
