require 'spec_helper'

describe CarrierWave::Uploader::Download do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#download!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')

      stub_request(:get, "www.example.com/test.jpg")
        .to_return(body: File.read(file_path("test.jpg")))

      stub_request(:get, "www.example.com/test-with-no-extension/test").
        to_return(body: File.read(file_path("test.jpg")), headers: { "Content-Type" => "image/jpeg" })

      stub_request(:get, "www.example.com/test%20with%20spaces/test.jpg").
        to_return(body: File.read(file_path("test.jpg")))

      stub_request(:get, "www.example.com/content-disposition").
        to_return(body: File.read(file_path("test.jpg")), headers: { "Content-Disposition" => 'filename="another_test.jpg"' })

      stub_request(:get, "www.redirect.com").
        to_return(status: 301, body: "Redirecting", headers: { "Location" => "http://www.example.com/test.jpg" })

      stub_request(:get, "www.example.com/missing.jpg").
        to_return(status: 404)
    end

    it 'should get url with baerer authorization on header' do
      stub_request(:get, "https://www.secure-exemple.com/test.png?access_token=VALID_TOKEN").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer VALID_TOKEN', 'User-Agent'=>'CarrierWave/0.10.0'}).
        to_return(:status => 200, :body => "", :headers => {})
      expect(@uploader.download!('https://www.secure-exemple.com/test.png?access_token=VALID_TOKEN')).to be nil
    end

    it "should cache a file" do
      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader).to be_cached
    end

    it "should store the cache name" do
      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader.cache_name).to eq('1369894322-345-1234-2255/test.jpg')
    end

    it "should set the filename to the file's sanitized filename" do
      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader.filename).to eq('test.jpg')
    end

    it "should move it to the tmp dir" do
      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader.file.path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/test.jpg'))
      expect(@uploader.file.exists?).to be_truthy
    end

    it "should set the url" do
      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/test.jpg')
    end

    it "should set permissions if options are given" do
      @uploader_class.permissions = 0777

      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader).to have_permissions(0777)
    end

    it "should set directory permissions if options are given" do
      @uploader_class.directory_permissions = 0777

      @uploader.download!('http://www.example.com/test.jpg')
      expect(@uploader).to have_directory_permissions(0777)
    end

    it "should raise an error when trying to download a local file" do
      expect(running {
        @uploader.download!('/etc/passwd')
      }).to raise_error(CarrierWave::DownloadError)
    end

    it "should raise an error when trying to download a missing file" do
      expect(running {
        @uploader.download!('http://www.example.com/missing.jpg')
      }).to raise_error(CarrierWave::DownloadError)
    end

    it "should accept spaces in the url" do
      @uploader.download!('http://www.example.com/test with spaces/test.jpg')
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/test.jpg')
    end

    it "should follow redirects" do
      @uploader.download!('http://www.redirect.com/')
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/test.jpg')
    end

    it "should read content-disposition headers" do
      @uploader.download!('http://www.example.com/content-disposition')
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/another_test.jpg')
    end

    it 'should set file extension based on content-type if missing' do
      @uploader.download!('http://www.example.com/test-with-no-extension/test')
      expect(@uploader.url).to match %r{/uploads/tmp/1369894322-345-1234-2255/test\.jp(e|e?g)$}
    end

    it 'should not obscure original exception message' do
      expect {
        @uploader.download!('http://www.example.com/missing.jpg')
      }.to raise_error(CarrierWave::DownloadError, /could not download file: 404/)
    end

    describe '#download! with an extension_whitelist' do
      before do
        @uploader_class.class_eval do
          def extension_whitelist
            %w(txt)
          end
        end
      end

      it "should follow redirects but still respect the extension_whitelist" do
        expect(running {
          @uploader.download!('http://www.redirect.com/')
        }).to raise_error(CarrierWave::IntegrityError)
      end

      it "should read content-disposition header but still respect the extension_whitelist" do
        expect(running {
          @uploader.download!('http://www.example.com/content-disposition')
        }).to raise_error(CarrierWave::IntegrityError)
      end
    end

    describe '#download! with an extension_blacklist' do
      before do
        @uploader_class.class_eval do
          def extension_blacklist
            %w(jpg)
          end
        end
      end

      it "should follow redirects but still respect the extension_blacklist" do
        expect(running {
          @uploader.download!('http://www.redirect.com/')
        }).to raise_error(CarrierWave::IntegrityError)
      end

      it "should read content-disposition header but still respect the extension_blacklist" do
        expect(running {
          @uploader.download!('http://www.example.com/content-disposition')
        }).to raise_error(CarrierWave::IntegrityError)
      end
    end
  end

  describe '#download! with an overridden process_uri method' do
    before do
      @uploader_class.class_eval do
        def process_uri(uri)
          raise CarrierWave::DownloadError
        end
      end
    end

    it "should allow overriding the process_uri method" do
      expect(running {
        @uploader.download!('http://www.example.com/test.jpg')
      }).to raise_error(CarrierWave::DownloadError)
    end
  end

  describe '#process_uri' do
    it "should parse but not escape already escaped uris" do
      uri = 'http://example.com/%5B.jpg'
      processed = @uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq(uri)
    end

    it "should parse but not escape uris with query-string-only characters not needing escaping" do
      uri = 'http://example.com/?foo[]=bar'
      processed = @uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq(uri)
    end

    it "should escape and parse unescaped uris" do
      uri = 'http://example.com/ %[].jpg'
      processed = @uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq('http://example.com/%20%25%5B%5D.jpg')
    end

    it "should escape and parse brackets in uri paths without harming the query string" do
      uri = 'http://example.com/].jpg?test[]'
      processed = @uploader.process_uri(uri)
      expect(processed.class).to eq(URI::HTTP)
      expect(processed.to_s).to eq('http://example.com/%5D.jpg?test[]')
    end

    it "should throw an exception on bad uris" do
      uri = '~http:'
      expect { @uploader.process_uri(uri) }.to raise_error(CarrierWave::DownloadError)
    end
  end
end
