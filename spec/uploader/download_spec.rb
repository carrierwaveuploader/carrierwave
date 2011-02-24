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
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
      Kernel.stub!(:open).and_return('Response Body')
    end

    it "should cache a file" do
      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.should be_cached
    end

    it "should store the cache name" do
      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.cache_name.should == '20071201-1234-345-2255/file.png'
    end

    it "should set the filename to the file's sanitized filename" do
      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.filename.should == 'file.png'
    end

    it "should move it to the tmp dir" do
      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.file.path.should == public_path('uploads/tmp/20071201-1234-345-2255/file.png')
      @uploader.file.exists?.should be_true
    end

    it "should set the url" do
      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/file.png'
    end

    it "should do nothing when trying to download an empty file" do
      @uploader.download!(nil)
    end

    it "should set permissions if options are given" do
      @uploader_class.permissions = 0777

      @uploader.download!('http://www.example.com/test/file.png')
      @uploader.should have_permissions(0777)
    end

    it "should raise an error when trying to download a local file" do
      running {
        @uploader.download!('/etc/passwd')
      }.should raise_error(CarrierWave::DownloadError)
    end

    it "should accept spaces in the url" do
      @uploader.download!('http://www.example.com/test with spaces/file.png')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/file.png'
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
        @uploader.download!('http://www.example.com/test/file.png')
      }.should raise_error(CarrierWave::DownloadError)
    end
  end
end
