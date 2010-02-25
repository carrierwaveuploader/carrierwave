# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end
  
  after do
    FileUtils.rm_rf(public_path)
  end

  describe '.clean_cached_files!' do
    before do
      @cache_dir = File.expand_path(@uploader_class.cache_dir, CarrierWave.root)
      FileUtils.mkdir_p File.expand_path('20071201-1234-234-2213', @cache_dir)
      FileUtils.mkdir_p File.expand_path('20071203-1234-234-2213', @cache_dir)
      FileUtils.mkdir_p File.expand_path('20071205-1234-234-2213', @cache_dir)
    end

    after { FileUtils.rm_rf(@cache_dir) }

    it "should clear all files older than 24 hours in the default cache directory" do
      Timecop.freeze(Time.parse('2007-12-06 10:12')) do
        @uploader_class.clean_cached_files!
      end
      Dir.glob("#{@cache_dir}/*").should have(1).element
    end

    it "should be aliased on the CarrierWave module" do
      Timecop.freeze(Time.parse('2007-12-06 10:12')) do
        CarrierWave.clean_cached_files!
      end
      Dir.glob("#{@cache_dir}/*").should have(1).element
    end
  end

  describe '#cache_dir' do
    it "should default to the config option" do
      @uploader.cache_dir.should == 'uploads/tmp'
    end
  end

  describe '#cache!' do

    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should cache a file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should be_cached
    end

    it "should store the cache name" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.cache_name.should == '20071201-1234-345-2255/test.jpg'
    end

    it "should set the filename to the file's sanitized filename" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.filename.should == 'test.jpg'
    end

    it "should move it to the tmp dir" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
      @uploader.file.exists?.should be_true
    end

    it "should set the url" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end

    it "should raise an error when trying to cache a string" do
      running {
        @uploader.cache!(file_path('test.jpg'))
      }.should raise_error(CarrierWave::FormNotMultipart)
    end

    it "should raise an error when trying to cache a pathname" do
      running {
        @uploader.cache!(Pathname.new(file_path('test.jpg')))
      }.should raise_error(CarrierWave::FormNotMultipart)
    end

    it "should do nothing when trying to cache an empty file" do
      @uploader.cache!(nil)
    end

    it "should set permissions if options are given" do
      @uploader_class.permissions = 0777

      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should have_permissions(0777)
    end
  end

  describe '#retrieve_from_cache!' do
    it "should cache a file" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.should be_cached
    end

    it "should set the path to the tmp dir" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end

    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/bork.txt')
    end

    it "should store the cache_name" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.cache_name.should == '20071201-1234-345-2255/test.jpeg'
    end

    it "should store the filename" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.filename.should == 'test.jpeg'
    end

    it "should set the url" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpeg'
    end

    it "should raise an error when the cache_id has an invalid format" do
      running {
        @uploader.retrieve_from_cache!('12345/test.jpeg')
      }.should raise_error(CarrierWave::InvalidParameter)

      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end

    it "should raise an error when the original_filename contains invalid characters" do
      running {
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/te/st.jpeg')
      }.should raise_error(CarrierWave::InvalidParameter)
      running {
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/te??%st.jpeg')
      }.should raise_error(CarrierWave::InvalidParameter)

      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end
  end

  describe 'with an overridden, reversing, filename' do
    before do
      @uploader_class.class_eval do
        def filename
          super.reverse unless super.blank?
        end
      end
    end

    describe '#cache!' do

      before do
        CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
      end

      it "should set the filename to the file's reversed filename" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.filename.should == "gpj.tset"
      end

      it "should move it to the tmp dir with the filename unreversed" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
        @uploader.file.exists?.should be_true
      end
    end

    describe '#retrieve_from_cache!' do
      it "should set the path to the tmp dir" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
      end

      it "should set the filename to the reversed name of the file" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.filename.should == "gpj.tset"
      end
    end
  end

end
