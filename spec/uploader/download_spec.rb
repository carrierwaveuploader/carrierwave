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
    let(:long_filename) { 'TgFCbMcysSV0v3-JJyvP02lfjh-XzbRxjsNpECoDJEsnoUUro9me195pWTE597xl6p6vDjo5sn5bGMjS40MRwMIsAsbNpqKfqdO19xvFbyPrVeXrkUMDeF_YjMUPXeVkRGdE3nGkK2zgwBCMAMMu2aU06Vod1FvslJaoasIFwqqF_jzolk2ot8nXlwTFvXt82CAV-a6gwqXFFdIfwRlCSF3gLGlfuPqSPzPxamwyDhzcJaf-eSMrsLE1-YA4BUZmEwD9hDKWusnpQ4jqGEbPBP5BKkM-HWPmxkVzkcQahtvQnlA' }
    let(:long_url_without_extension) { 'http://www.example.com/' + long_filename }
    let(:long_url) { long_url_without_extension + '.jpg' }

    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')

      sham_rack_app = ShamRack.at('www.example.com').stub
      sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      sham_rack_app.register_resource('/test%20with%20spaces/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      sham_rack_app.register_resource('/' + long_filename + '.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      sham_rack_app.register_resource('/' + long_filename, File.read(file_path('test.jpg')), 'image/jpg')

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

    context "on a remote file with a long filename" do
      context "when the remote filename has no extension" do
        it "should only use part of the original filename" do
          @uploader.download!(long_url_without_extension)
          @uploader.filename.size.should <= 255
          @uploader.filename.should =~ /^#{long_url.split("/").last[0,221]}__/
        end
      end

      context "when the remote filename has a proper extension" do
        it "should only use part of the original filename" do
          @uploader.download!(long_url)
          @uploader.filename.size.should <= 255
          @uploader.filename.should =~ /^#{long_url.split("/").last[0,217]}__/
        end

        it "should retain the extension" do
          @uploader.download!(long_url)
          @uploader.filename.should =~ /\.jpg$/
        end
      end
    end

    it "should be cached" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.should be_cached
    end

    it "should store the cache name" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.cache_name.should == '20071201-1234-345-2255/test.jpg'
    end

    it "should set the filename to the file's sanitized filename" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.filename.should == 'test.jpg'
    end

    it "should move it to the tmp dir" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.file.path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
      @uploader.file.exists?.should be_true
    end

    it "should set the url" do
      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end

    it "should do nothing when trying to download an empty file" do
      @uploader.download!(nil)
    end

    it "should set permissions if options are given" do
      @uploader_class.permissions = 0777

      @uploader.download!('http://www.example.com/test.jpg')
      @uploader.should have_permissions(0777)
    end

    it "should raise an error when trying to download a local file" do
      running {
        @uploader.download!('/etc/passwd')
      }.should raise_error(CarrierWave::DownloadError)
    end

    it "should accept spaces in the url" do
      @uploader.download!('http://www.example.com/test with spaces/test.jpg')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end

    it "should follow redirects" do
      @uploader.download!('http://www.redirect.com/')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
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
    let(:uri) { "http://www.example.com/test%20image.jpg" }

    it 'should unescape and then escape the given uri' do
      unescaped_uri = URI.unescape(uri)
      @uploader.process_uri(unescaped_uri).should == @uploader.process_uri(uri)
    end

    it 'should parse the given uri' do
      @uploader.process_uri(uri).should == URI.parse(uri)
    end
  end
end
