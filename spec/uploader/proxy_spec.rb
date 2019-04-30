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

  describe '#blank?' do
    it "should be true when nothing has been done" do
      @uploader.should be_blank
    end

    it "should not be true when the file is empty" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.should be_blank
    end

    it "should not be true when a file has been cached" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should_not be_blank
    end
  end

  describe '#read' do
    it "should be nil by default" do
      @uploader.read.should be_nil
    end

    it "should read the contents of a cached file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.read.should == "this is stuff"
    end
  end

  describe '#size' do
    it "should be zero by default" do
      @uploader.size.should == 0
    end

    it "should get the size of a cached file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.size.should == 13
    end
  end

  describe '#content_type' do
    it "should be nil when nothing has been done" do
      @uploader.content_type.should be_nil
    end

    it "should get the content type when the file has been cached" do
      @uploader.cache!(File.open(file_path('landscape.jpg')))
      @uploader.content_type.should == 'image/jpeg'
    end

    it "should get the content type when the file is empty" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.content_type.should == 'image/jpeg'
    end
  end

end
