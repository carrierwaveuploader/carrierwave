# encoding: utf-8

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
      CarrierWave.stub!(:generate_cache_id).and_return('1369894322-345-2255')

      sham_rack_app = ShamRack.at('www.example.com').stub
      sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      sham_rack_app.register_resource('/test%20with%20spaces/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      sham_rack_app.handle do |request|
        if request.path_info == '/content-disposition'
          ["200 OK", {'Content-Type'=>'image/jpg', 'Content-Disposition'=>'filename="another_test.jpg"'}, [File.read(file_path('test.jpg'))]]
        end
      end

      ShamRack.at("www.redirect.com") do |env|
        [301, {'Content-Type'=>'text/html', 'Location'=>"http://www.example.com/test.jpg"}, ['Redirecting']]
      end
    end

    after do
      ShamRack.unmount_all
    end

    it "should cache a file" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.should be_cached
    end

    it "should store the cache name" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.cache_name.should == '1369894322-345-2255/test.jpg'
    end

    it "should set the filename to the file's sanitized filename" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.filename.should == 'test.jpg'
    end

    it "should move it to the tmp dir" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.file.path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpg')
      @uploader.file.exists?.should be_true
    end

    it "should set the url" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.url.should == '/uploads/tmp/1369894322-345-2255/test.jpg'
    end

    it "should do nothing when trying to download an empty file" do
      @uploader.download!(nil)
    end

    it "should set permissions if options are given" do
      @uploader_class.permissions = 0777

      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.should have_permissions(0777)
    end

    it "should set directory permissions if options are given" do
      @uploader_class.directory_permissions = 0777

      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.should have_directory_permissions(0777)
    end

    it "should raise an error when trying to download a local file" do
      running {
        @uploader.download!('/etc/passwd')
      }.should raise_error(CarrierWave::DownloadError)
    end

    it "should raise an error when trying to download a missing file" do
      running {
        @uploader.download!('http://www.example.com/missing.jpg')
      }.should raise_error(CarrierWave::DownloadError)
    end

    it "should accept spaces in the url" do
      @uploader.download!('http://www.example.com/test with spaces/test.jpg')
      @uploader.url.should == '/uploads/tmp/1369894322-345-2255/test.jpg'
    end

    it "should follow redirects" do
      @uploader.download!('http://www.redirect.com/')
      @uploader.url.should == '/uploads/tmp/1369894322-345-2255/test.jpg'
    end

    it "should read content-disposition headers" do
      @uploader.download!('http://www.example.com/content-disposition')
      @uploader.url.should == '/uploads/tmp/1369894322-345-2255/another_test.jpg'
    end

    it 'should not obscure original exception message' do
      expect {
        @uploader.download!('http://www.example.com/missing.jpg')
      }.to raise_error(CarrierWave::DownloadError, 'could not download file: 404 Not Found')
    end

    describe '#download! with an extension_white_list' do
      before do
        @uploader_class.class_eval do
          def extension_white_list
            %w(txt)
          end
        end
      end

      it "should follow redirects but still respect the extension_white_list" do
        running {
          @uploader.download!('http://www.redirect.com/')
        }.should raise_error(CarrierWave::IntegrityError)
      end

      it "should read content-disposition header but still respect the extension_white_list" do
        running {
          @uploader.download!('http://www.example.com/content-disposition')
        }.should raise_error(CarrierWave::IntegrityError)
      end
    end

    describe '#download! with an extension_black_list' do
      before do
        @uploader_class.class_eval do
          def extension_black_list
            %w(jpg)
          end
        end
      end

      it "should follow redirects but still respect the extension_black_list" do
        running {
          @uploader.download!('http://www.redirect.com/')
        }.should raise_error(CarrierWave::IntegrityError)
      end

      it "should read content-disposition header but still respect the extension_black_list" do
        running {
          @uploader.download!('http://www.example.com/content-disposition')
        }.should raise_error(CarrierWave::IntegrityError)
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
      running {
        @uploader.download!('http://www.example.com/test.jpg')
      }.should raise_error(CarrierWave::DownloadError)
    end
  end

  describe '#process_uri' do
    it "should parse but not escape already escaped uris" do
      uri = 'http://example.com/%5B.jpg'
      processed = @uploader.process_uri(uri)
      processed.class.should == URI::HTTP
      processed.to_s.should == uri
    end

    it "should parse but not escape uris with query-string-only characters not needing escaping" do
      uri = 'http://example.com/?foo[]=bar'
      processed = @uploader.process_uri(uri)
      processed.class.should == URI::HTTP
      processed.to_s.should == uri
    end

    it "should escape and parse unescaped uris" do
      uri = 'http://example.com/ %[].jpg'
      processed = @uploader.process_uri(uri)
      processed.class.should == URI::HTTP
      processed.to_s.should == 'http://example.com/%20%25%5B%5D.jpg'
    end

    it "should escape and parse brackets in uri paths without harming the query string" do
      uri = 'http://example.com/].jpg?test[]'
      processed = @uploader.process_uri(uri)
      processed.class.should == URI::HTTP
      processed.to_s.should == 'http://example.com/%5D.jpg?test[]'
    end

    it "should throw an exception on bad uris" do
      uri = '~http:'
      expect { @uploader.process_uri(uri) }.to raise_error(CarrierWave::DownloadError)
    end
  end
end
