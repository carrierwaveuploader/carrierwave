require 'spec_helper'

describe CarrierWave::Downloader::Base do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:file) { File.read(file_path("test.jpg")) }
  let(:filename) { "test.jpg" }
  let(:uri) { "http://www.example.com/#{URI::DEFAULT_PARSER.escape(filename)}" }

  subject { CarrierWave::Downloader::Base.new(uploader) }

  context "with unicode symbols in URL" do
    let(:filename) { "юникод.jpg" }
    before do
      stub_request(:get, uri).to_return(body: file)
    end

    let(:remote_file) { subject.download(uri) }

    it "downloads a file" do
      expect(remote_file).to be_an_instance_of(CarrierWave::Downloader::RemoteFile)
    end

    it "sets the filename to the file's decoded sanitized filename" do
      expect(remote_file.original_filename).to eq(filename)
    end
  end

  context "with equal and colons in the query path" do
    let(:query) { 'test=query&with=equal&before=colon:param' }
    let(:uri) { "https://example.com/#{filename}?#{query}" }
    before do
      stub_request(:get, uri).to_return(body: file)
    end

    it "leaves colon in resulting URI" do
      expect(subject.process_uri(uri).query).to eq query
    end

    it "downloads a file" do
      expect(subject.download(uri).file.read).to eq file
    end
  end

  context "with internationalized domain name" do
    let(:uri) { "https://ドメイン名例.jp/test.jpg" }
    before do
      stub_request(:get, 'https://xn--eckwd4c7cu47r2wf.jp/test.jpg').to_return(body: file)
      allow(Resolv).to receive(:getaddresses).with('xn--eckwd4c7cu47r2wf.jp').and_return(['1.2.3.4'])
    end

    it "downloads a file" do
      expect(subject.download(uri).file.read).to eq file
    end
  end

  context "with non-ascii characters in the query and the fragment" do
    let(:uri) { "http://example.com/test.jpg?q=А#あああ" }
    before do
      stub_request(:get, "http://example.com/test.jpg?q=%D0%90").to_return(body: file)
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

  context "with server error" do
    before do
      stub_request(:get, uri).to_return(status: 500)
    end

    it "raises an error when trying to download" do
      expect{ subject.download(uri) }.to raise_error(CarrierWave::DownloadError)
    end

    it "doesn't obscure original exception message" do
      expect { subject.download(uri) }.to raise_error(CarrierWave::DownloadError, /could not download file: 500/)
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
      stub_request(:get, /redirected.jpg/).to_return(body: file)
    end

    it "retrieves redirected file" do
      expect(subject.download(uri).file.read).to eq file
    end

    it "extracts filename from the url after redirection" do
      expect(subject.download(uri).original_filename).to eq 'redirected.jpg'
    end
  end

  context "with SSRF prevention" do
    before do
      stub_request(:get, 'http://169.254.169.254/').to_return(body: file)
      stub_request(:get, 'http://127.0.0.1/').to_return(body: file)
    end

    it "prevents accessing local files" do
      expect { subject.download('/etc/passwd') }.to raise_error(CarrierWave::DownloadError)
      expect { subject.download('file:///etc/passwd') }.to raise_error(CarrierWave::DownloadError)
    end

    it "prevents accessing internal addresses" do
      expect { uploader.download!("http://169.254.169.254/") }.to raise_error CarrierWave::DownloadError
      expect { uploader.download!("http://lvh.me/") }.to raise_error CarrierWave::DownloadError
    end
  end

  context 'with download_retry_count' do
    before do
      stub_request(:get, uri).to_return({ status: 503 }, { status: 200 })
    end
    let(:instance) { described_class.new(uploader) }
    subject { instance.download uri }
    context 'when download_retry_count == 0 ' do
      before do
        uploader.download_retry_count = 0
      end
      it 'throws an exception' do
        expect { subject }.to raise_error CarrierWave::DownloadError
      end
    end

    context 'when download_retry_count > 0' do
      before do
        uploader.download_retry_count = 1
        uploader.download_retry_wait_time = 0.01
      end
      it 'does not throw an exception' do
        expect { subject }.not_to raise_error
      end
    end
  end

  context 'when actually downloading a file' do
    let(:uri) { 'https://raw.githubusercontent.com/carrierwaveuploader/carrierwave/master/spec/fixtures/test.jpg' }
    before { WebMock.disable! }
    after { WebMock.enable! }

    it 'retrieves the body successfully' do
      expect(subject.download(uri).file.read).to eq 'this is stuff'
    end
  end

  describe '#process_uri' do
    it "returns an URI instance" do
      uri = "http://example.com/"
      expect(subject.process_uri(uri)).to be_an_instance_of(URI::HTTP)
    end

    it "converts a URL with internationalized domain name to Punycode URI" do
      uri = "http://ドメイン名例.jp/#{CGI.escape(filename)}"
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq 'http://xn--eckwd4c7cu47r2wf.jp/test.jpg'
    end

    it "parses but not escape already escaped uris" do
      uri = 'http://example.com/%5B.jpg'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq(uri)
    end

    it "does not perform normalization on path when not necessary" do
      uri = 'http://example.com/o%CC%88.png'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq(uri)
    end

    it "parses but not escape uris with query-string-only characters not needing escaping" do
      uri = 'http://example.com/?foo[]=bar'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq(uri)
    end

    it "escapes and parse unescaped uris" do
      uri = 'http://example.com/ %[].jpg'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq('http://example.com/%20%25%5B%5D.jpg')
    end

    it "parses but not escape uris with query-string characters representing urls not needing escaping " do
      uri = 'http://example.com/?src0=https%3A%2F%2Fi.vimeocdn.com%2Fvideo%2F1234_1280x720.jpg'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq(uri)
    end

    it "escapes and parse brackets in uri paths without harming the query string" do
      uri = 'http://example.com/].jpg?test[]'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq('http://example.com/%5D.jpg?test[]')
    end

    it "escapes and parse unescaped characters in path" do
      uri = 'http://example.com/あああ.jpg'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq('http://example.com/%E3%81%82%E3%81%82%E3%81%82.jpg')
    end

    it "escapes and parse unescaped characters in query string" do
      uri = 'http://example.com/?q=あああ'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq('http://example.com/?q=%E3%81%82%E3%81%82%E3%81%82')
    end

    it "escapes and parse unescaped characters in the fragment" do
      uri = 'http://example.com/#あああ'
      processed = subject.process_uri(uri)
      expect(processed.to_s).to eq('http://example.com/#%E3%81%82%E3%81%82%E3%81%82')
    end

    it "throws an exception on bad uris" do
      uri = '~http:'
      expect { subject.process_uri(uri) }.to raise_error(CarrierWave::DownloadError)
    end
  end

  describe "#skip_ssrf_protection?" do
    context "when ssrf_protection is skipped" do
      let(:uri) { 'http://localhost/test.jpg' }
      before do
        WebMock.stub_request(:get, uri).to_return(body: file)
        allow(subject).to receive(:skip_ssrf_protection?).and_return(true)
      end

      it "allows local request to be made" do
        expect(subject.download(uri).read).to eq 'this is stuff'
      end
    end

    context 'skip_ssrf_protection configuration' do
      it 'defaults to false' do
        expect(subject.skip_ssrf_protection?(uri)).to be_falsey
      end

      it 'can be configured by skip_ssrf_protection config' do
        uploader.skip_ssrf_protection = true
        expect(subject.skip_ssrf_protection?(uri)).to be_truthy
      end
    end
  end
end
