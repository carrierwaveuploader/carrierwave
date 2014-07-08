# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe 'with a default url' do
    before do
      @uploader_class.class_eval do
        version :thumb
        def default_url
          ["http://someurl.example.com", version_name].compact.join('/')
        end
      end
      @uploader = @uploader_class.new
    end

    describe '#blank?' do
      it "should be true by default" do
        @uploader.should be_blank
      end
    end

    describe '#current_path' do
      it "should return nil" do
        @uploader.current_path.should be_nil
      end
    end

    describe '#url' do
      it "should return the default url" do
        @uploader.url.should == 'http://someurl.example.com'
      end

      it "should return the default url with version when given" do
        @uploader.url(:thumb).should == 'http://someurl.example.com/thumb'
      end
    end

    describe '#cache!' do

      before do
        CarrierWave.stub(:generate_cache_id).and_return('1369894322-345-2255')
      end

      it "should cache a file" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
      end

      it "should be cached" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.should be_cached
      end

      it "should no longer be blank" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.should_not be_blank
      end

      it "should set the current_path" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.current_path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpg')
      end

      it "should set the url" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.url.should_not == 'http://someurl.example.com'
        @uploader.url.should == '/uploads/tmp/1369894322-345-2255/test.jpg'
      end

    end

  end

end
