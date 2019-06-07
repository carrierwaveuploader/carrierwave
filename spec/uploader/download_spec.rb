require 'spec_helper'

describe CarrierWave::Uploader::Download do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '1369894322-345-1234-2255' }
  let(:base_url) { "http://www.example.com" }
  let(:url) { base_url + "/test.jpg" }
  let(:test_file) { File.read(file_path(test_file_name)) }
  let(:test_file_name) { "test.jpg" }
  let(:content_disposition){ 'filename="another_test.jpg"' }
  let(:unicode_named_file) { File.read(file_path(unicode_filename)) }
  let(:unicode_URL) { URI.encode(base_url + "/#{unicode_filename}") }
  let(:unicode_filename) { "юникод.jpg" }
  let(:authentication_headers) do
    {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent'=>"CarrierWave/#{CarrierWave::VERSION}",
      'Authorization'=>'Bearer QWE'
    }
  end

  after { FileUtils.rm_rf(public_path) }

  describe '#download!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id)

      stub_request(:get, "www.example.com/#{test_file_name}")
        .to_return(body: test_file)

      stub_request(:get, "www.example.com/test-with-no-extension/test").
        to_return(body: test_file, headers: { "Content-Type" => "image/jpeg" })

      stub_request(:get, "www.example.com/test%20with%20spaces/#{test_file_name}").
        to_return(body: test_file)

      stub_request(:get, "www.example.com/content-disposition").
        to_return(body: test_file, headers: { "Content-Disposition" => content_disposition })

      stub_request(:get, "www.redirect.com").
        to_return(status: 301, body: "Redirecting", headers: { "Location" => url })

      stub_request(:get, "www.example.com/missing.jpg").
        to_return(status: 404)

      stub_request(:get, "www.example.com/authorization_required.jpg").
        with(:headers => authentication_headers).
        to_return(body: test_file)

      stub_request(:get, unicode_URL).to_return(body: unicode_named_file)
    end

    context "when a file was downloaded" do
      before do
        uploader.download!(url)
      end

      it "caches a file" do
        expect(uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
      end

      it "'s cached" do
        expect(uploader).to be_cached
      end

      it "stores the cache name" do
        expect(uploader.cache_name).to eq("#{cache_id}/#{test_file_name}")
      end

      it "sets the filename to the file's sanitized filename" do
        expect(uploader.filename).to eq("#{test_file_name}")
      end

      it "moves it to the tmp dir" do
        expect(uploader.file.path).to eq(public_path("uploads/tmp/#{cache_id}/#{test_file_name}"))
        expect(uploader.file.exists?).to be_truthy
      end

      it "sets the url" do
        expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
      end
    end

    context "with unicode sybmols in URL" do
      before do
        uploader.download!(unicode_URL)
      end

      it "caches a file" do
        expect(uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
      end

      it "sets the filename to the file's decoded sanitized filename" do
        expect(uploader.filename).to eq("#{unicode_filename}")
      end

      it "moves it to the tmp dir" do
        expect(uploader.file.path).to eq(public_path("uploads/tmp/#{cache_id}/#{unicode_filename}"))
        expect(uploader.file.exists?).to be_truthy
      end
    end

    context "with directory permissions set" do
      let(:permissions) { 0777 }

      it "sets permissions" do
        uploader_class.permissions = permissions
        uploader.download!(url)

        expect(uploader).to have_permissions(permissions)
      end

      it "sets directory permissions" do
        uploader_class.directory_permissions = permissions
        uploader.download!(url)

        expect(uploader).to have_directory_permissions(permissions)
      end
    end

    context 'with request headers' do
      it 'pass custom headers to request' do
        auth_required_url = 'http://www.example.com/authorization_required.jpg'
        uploader.download!(auth_required_url, { 'Authorization' => 'Bearer QWE' })
        expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/authorization_required.jpg")
      end
    end

    it "raises an error when trying to download a local file" do
      expect { uploader.download!('/etc/passwd') }.to raise_error(CarrierWave::DownloadError)
    end

    it "raises an error when trying to download a missing file" do
      expect{ uploader.download!("#{base_url}/missing.jpg") }.to raise_error(CarrierWave::DownloadError)
    end

    it "accepts spaces in the url" do
      uploader.download!(url)
      expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
    end

    it "follows redirects" do
      uploader.download!('http://www.redirect.com/')
      expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
    end

    describe 'with content-disposition' do
      context 'when filename is quoted' do
        it "reads filename correctly" do
          uploader.download!("#{base_url}/content-disposition")
          expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/another_#{test_file_name}")
        end
      end

      context 'when filename is not quoted' do
        let(:content_disposition){ 'filename=another_test.jpg' }

        it "reads filename correctly" do
          uploader.download!("#{base_url}/content-disposition")
          expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/another_#{test_file_name}")
        end
      end

      context 'when filename is not quoted and terminated by semicolon' do
        let(:content_disposition){ 'filename=another_test.jpg; size=1234' }

        it "reads filename correctly" do
          uploader.download!("#{base_url}/content-disposition")
          expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/another_#{test_file_name}")
        end
      end

      context 'when filename is quoted and contains a semicolon' do
        let(:content_disposition){ 'filename="another;_test.jpg"; size=1234' }

        it "reads filename and replaces semicolon correctly" do
          uploader.download!("#{base_url}/content-disposition")
          expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/another__#{test_file_name}")
        end
      end
    end

    it 'sets file extension based on content-type if missing' do
      uploader.download!("#{base_url}/test-with-no-extension/test")

      expect(uploader.url).to match %r{/uploads/tmp/#{cache_id}/test\.jp(e|e?g)$}
    end

    it "doesn't obscure original exception message" do
      expect { uploader.download!("#{base_url}/missing.jpg") }.to raise_error(CarrierWave::DownloadError, /could not download file: 404/)
    end

    describe '#download! with an extension_whitelist' do
      before do
        uploader_class.class_eval do
          def extension_whitelist
            %w(txt)
          end
        end
      end

      it "follows redirects but still respect the extension_whitelist" do
        expect { uploader.download!('http://www.redirect.com/') }.to raise_error(CarrierWave::IntegrityError)
      end

      it "reads content-disposition header but still respect the extension_whitelist" do
        expect { uploader.download!("#{base_url}/content-disposition") }.to raise_error(CarrierWave::IntegrityError)
      end
    end

    describe '#download! with an extension_blacklist' do
      before do
        uploader_class.class_eval do
          def extension_blacklist
            %w(jpg)
          end
        end
      end

      it "follows redirects but still respect the extension_blacklist" do
        expect { uploader.download!('http://www.redirect.com/') }.to raise_error(CarrierWave::IntegrityError)
      end

      it "reads content-disposition header but still respect the extension_blacklist" do
        expect { uploader.download!("#{base_url}/content-disposition") }.to raise_error(CarrierWave::IntegrityError)
      end
    end
  end

  describe '#download! with an overridden process_uri method' do
    before do
      uploader_class.class_eval do
        def process_uri(uri)
          raise CarrierWave::DownloadError
        end
      end
    end

    it "allows overriding the process_uri method" do
      expect { uploader.download!(url) }.to raise_error(CarrierWave::DownloadError)
    end
  end

  describe '#process_uri' do
    it "parses but not escape already escaped uris" do
      uri = 'http://example.com/%5B.jpg'
      processed = uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq(uri)
    end

    it "parses but not escape uris with query-string-only characters not needing escaping" do
      uri = 'http://example.com/?foo[]=bar'
      processed = uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq(uri)
    end

    it "escapes and parse unescaped uris" do
      uri = 'http://example.com/ %[].jpg'
      processed = uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq('http://example.com/%20%25%5B%5D.jpg')
    end

    it "escapes and parse brackets in uri paths without harming the query string" do
      uri = 'http://example.com/].jpg?test[]'
      processed = uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq('http://example.com/%5D.jpg?test[]')
    end

    it "throws an exception on bad uris" do
      uri = '~http:'
      expect { uploader.process_uri(uri) }.to raise_error(CarrierWave::DownloadError)
    end
  end
end
