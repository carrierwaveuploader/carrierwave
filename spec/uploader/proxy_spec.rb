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
      expect(@uploader).to be_blank
    end

    it "should not be true when the file is empty" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      expect(@uploader).to be_blank
    end

    it "should not be true when a file has been cached" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader).not_to be_blank
    end
  end

  describe '#read' do
    it "should be nil by default" do
      expect(@uploader.read).to be_nil
    end

    it "should read the contents of a cached file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.read).to eq("this is stuff")
    end
  end

  describe '#size' do
    it "should be zero by default" do
      expect(@uploader.size).to eq(0)
    end

    it "should get the size of a cached file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.size).to eq(13)
    end
  end

  describe '#content_type' do
    it "should be nil when nothing has been done" do
      expect(@uploader.content_type).to be_nil
    end

    it "should get the content type when the file has been cached" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.content_type).to eq('image/jpeg')
    end

    it "should get the content type when the file is empty" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      expect(@uploader.content_type).to eq('image/jpeg')
    end
  end

end
