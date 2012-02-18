# encoding: utf-8

require 'spec_helper'
require 'active_support/json'

describe CarrierWave::Uploader do

  before do
    class MyCoolUploader < CarrierWave::Uploader::Base; end
    @uploader = MyCoolUploader.new
  end

  after do
    FileUtils.rm_rf(public_path)
    Object.send(:remove_const, "MyCoolUploader") if defined?(::MyCoolUploader)
  end

  describe '#url' do
    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should default to nil" do
      @uploader.url.should be_nil
    end

    it "should raise ArgumentError when version doesn't exist" do
      lambda { @uploader.url(:thumb) }.should raise_error(ArgumentError)
    end

    it "should not raise exception when hash specified as argument" do
      lambda { @uploader.url({}) }.should_not raise_error
    end

    it "should not raise ArgumentError when storage's File#url method doesn't get params" do
      module StorageX; class File; def url; true; end; end; end
      @uploader.stub!(:file).and_return(StorageX::File.new)
      lambda { @uploader.url }.should_not raise_error
    end

    it "should not raise ArgumentError when versions version exists" do
      MyCoolUploader.version(:thumb)
      lambda { @uploader.url(:thumb) }.should_not raise_error(ArgumentError)
    end

    it "should get the directory relative to public, prepending a slash" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end

    it "should get the directory relative to public for a specific version" do
      MyCoolUploader.version(:thumb)
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url(:thumb).should == '/uploads/tmp/20071201-1234-345-2255/thumb_test.jpg'
    end

    it "should get the directory relative to public for a nested version" do
      MyCoolUploader.version(:thumb) do
        version(:mini)
      end
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url(:thumb, :mini).should == '/uploads/tmp/20071201-1234-345-2255/thumb_mini_test.jpg'
    end

    it "should prepend the config option 'base_path', if set" do
      MyCoolUploader.version(:thumb)
      @uploader.class.configure do |config|
        config.base_path = "/base_path"
      end
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url(:thumb).should == '/base_path/uploads/tmp/20071201-1234-345-2255/thumb_test.jpg'
    end

    it "should return file#url if available" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.stub!(:url).and_return('http://www.example.com/someurl.jpg')
      @uploader.url.should == 'http://www.example.com/someurl.jpg'
    end

    it "should get the directory relative to public, if file#url is blank" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.stub!(:url).and_return('')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end
  end

  describe '#to_json' do
    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should return a hash with a nil URL" do
      MyCoolUploader.version(:thumb)
      hash = JSON.parse(@uploader.to_json)
      hash.keys.should
      hash.keys.should include("uploader")
      hash["uploader"].keys.should include("url")
      hash["uploader"].keys.should include("thumb")
      hash["uploader"]["url"].should be_nil
      hash["uploader"]["thumb"].keys.should include("url")
      hash["uploader"]["thumb"]["url"].should be_nil
    end

    it "should return a hash including a cached URL" do
      @uploader.cache!(File.open(file_path("test.jpg")))
      JSON.parse(@uploader.to_json).should == {"uploader" => {"url" => "/uploads/tmp/20071201-1234-345-2255/test.jpg"}}
    end

    it "should return a hash including a cached URL of a version" do
      MyCoolUploader.version(:thumb)
      @uploader.cache!(File.open(file_path("test.jpg")))
      hash = JSON.parse(@uploader.to_json)["uploader"]
      hash.keys.should include "thumb"
      hash["thumb"].should == {"url" => "/uploads/tmp/20071201-1234-345-2255/thumb_test.jpg"}
    end
  end

  describe '#to_xml' do
    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should return a hash with a blank URL" do
      Hash.from_xml(@uploader.to_xml).should == {"uploader" => {"url" => nil}}
    end

    it "should return a hash including a cached URL" do
      @uploader.cache!(File.open(file_path("test.jpg")))
      Hash.from_xml(@uploader.to_xml).should == {"uploader" => {"url" => "/uploads/tmp/20071201-1234-345-2255/test.jpg"}}
    end

    it "should return a hash including a cached URL of a version" do
      MyCoolUploader.version(:thumb)
      @uploader.cache!(File.open(file_path("test.jpg")))
      Hash.from_xml(@uploader.to_xml)["uploader"]["thumb"].should == {"url" => "/uploads/tmp/20071201-1234-345-2255/thumb_test.jpg"}
    end

    it "should return a hash including an array with a cached URL" do
      @uploader.cache!(File.open(file_path("test.jpg")))
      hash = Hash.from_xml([@uploader].to_xml)
      hash.should have_value([{"url"=>"/uploads/tmp/20071201-1234-345-2255/test.jpg"}])
    end
  end

  describe '#to_s' do
    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should default to empty space" do
      @uploader.to_s.should == ''
    end

    it "should get the directory relative to public, prepending a slash" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.to_s.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end

    it "should return file#url if available" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.stub!(:url).and_return('http://www.example.com/someurl.jpg')
      @uploader.to_s.should == 'http://www.example.com/someurl.jpg'
    end
  end

end
