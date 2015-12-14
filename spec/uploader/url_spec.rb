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
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "should default to nil" do
      expect(@uploader.url).to be_nil
    end

    it "should raise ArgumentError when version doesn't exist" do
      expect { @uploader.url(:thumb) }.to raise_error(ArgumentError)
    end

    it "should not raise exception when hash specified as argument" do
      expect { @uploader.url({}) }.not_to raise_error
    end

    it "should not raise ArgumentError when storage's File#url method doesn't get params" do
      module StorageX; class File; def url; true; end; end; end
      allow(@uploader).to receive(:file).and_return(StorageX::File.new)
      expect { @uploader.url }.not_to raise_error
    end

    it "should not raise ArgumentError when versions version exists" do
      MyCoolUploader.version(:thumb)
      expect { @uploader.url(:thumb) }.not_to raise_error
    end

    it "should get the directory relative to public, prepending a slash" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/test.jpg')
    end

    it "should get the directory relative to public for a specific version" do
      MyCoolUploader.version(:thumb)
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.url(:thumb)).to eq('/uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg')
    end

    it "should get the directory relative to public for a nested version" do
      MyCoolUploader.version(:thumb) do
        version(:mini)
      end
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.url(:thumb, :mini)).to eq('/uploads/tmp/1369894322-345-1234-2255/thumb_mini_test.jpg')
    end

    it "should prepend the config option 'asset_host', if set and a string" do
      MyCoolUploader.version(:thumb)
      @uploader.class.configure do |config|
        config.asset_host = "http://foo.bar"
      end
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.url(:thumb)).to eq('http://foo.bar/uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg')
    end

    it "should prepend the result of the config option 'asset_host', if set and a proc" do
      MyCoolUploader.version(:thumb)
      @uploader.class.configure do |config|
        config.asset_host = proc { "http://foo.bar" }
      end
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.url(:thumb)).to eq('http://foo.bar/uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg')
    end

    it "should prepend the config option 'base_path', if set and 'asset_host' is not set" do
      MyCoolUploader.version(:thumb)
      @uploader.class.configure do |config|
        config.base_path = "/base_path"
        config.asset_host = nil
      end
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.url(:thumb)).to eq('/base_path/uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg')
    end

    it "should return file#url if available" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      allow(@uploader.file).to receive(:url).and_return('http://www.example.com/someurl.jpg')
      expect(@uploader.url).to eq('http://www.example.com/someurl.jpg')
    end

    it "should get the directory relative to public, if file#url is blank" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      allow(@uploader.file).to receive(:url).and_return('')
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/test.jpg')
    end

    it "should uri encode the path of a file without an asset host" do
      @uploader.cache!(File.open(file_path('test+.jpg')))
      expect(@uploader.url).to eq('/uploads/tmp/1369894322-345-1234-2255/test%2B.jpg')
    end

    it "should uri encode the path of a file with a string asset host" do
      MyCoolUploader.version(:thumb)
      @uploader.class.configure do |config|
        config.asset_host = "http://foo.bar"
      end
      @uploader.cache!(File.open(file_path('test+.jpg')))
      expect(@uploader.url(:thumb)).to eq('http://foo.bar/uploads/tmp/1369894322-345-1234-2255/thumb_test%2B.jpg')
    end

    it "should uri encode the path of a file with a proc asset host" do
      MyCoolUploader.version(:thumb)
      @uploader.class.configure do |config|
        config.asset_host = proc { "http://foo.bar" }
      end
      @uploader.cache!(File.open(file_path('test+.jpg')))
      expect(@uploader.url(:thumb)).to eq('http://foo.bar/uploads/tmp/1369894322-345-1234-2255/thumb_test%2B.jpg')
    end

    it "shouldn't double-encode the path of an available file#url" do
      url = 'http://www.example.com/directory%2Bname/another%2Bdirectory/some%2Burl.jpg'
      @uploader.cache!(File.open(file_path('test.jpg')))
      allow(@uploader.file).to receive(:url).and_return(url)
      expect(@uploader.url).to eq(url)
    end
  end

  describe '#to_json' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "should return a hash with a nil URL" do
      MyCoolUploader.version(:thumb)
      hash = JSON.parse(@uploader.to_json)
      expect(hash.keys).to include("url")
      expect(hash.keys).to include("thumb")
      expect(hash["url"]).to be_nil
      expect(hash["thumb"].keys).to include("url")
      expect(hash["thumb"]["url"]).to be_nil
    end

    it "should return a hash including a cached URL" do
      @uploader.cache!(File.open(file_path("test.jpg")))
      expect(JSON.parse(@uploader.to_json)).to eq({"url" => "/uploads/tmp/1369894322-345-1234-2255/test.jpg"})
    end

    it "should return a hash including a cached URL of a version" do
      MyCoolUploader.version(:thumb)
      @uploader.cache!(File.open(file_path("test.jpg")))
      hash = JSON.parse(@uploader.to_json)
      expect(hash.keys).to include "thumb"
      expect(hash["thumb"]).to eq({"url" => "/uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg"})
    end

    it "should allow an options parameter to be passed in" do
      expect { @uploader.to_json({:some => 'options'}) }.not_to raise_error
    end
  end

  describe '#to_xml' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "should return a hash with a blank URL" do
      expect(Hash.from_xml(@uploader.to_xml)).to eq({"uploader" => {"url" => nil}})
    end

    it "should return a hash including a cached URL" do
      @uploader.cache!(File.open(file_path("test.jpg")))
      expect(Hash.from_xml(@uploader.to_xml)).to eq({"uploader" => {"url" => "/uploads/tmp/1369894322-345-1234-2255/test.jpg"}})
    end

    it "should return a hash including a cached URL of a version" do
      MyCoolUploader.version(:thumb)
      @uploader.cache!(File.open(file_path("test.jpg")))
      expect(Hash.from_xml(@uploader.to_xml)["uploader"]["thumb"]).to eq({"url" => "/uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg"})
    end

    it "should return a hash including an array with a cached URL" do
      @uploader.cache!(File.open(file_path("test.jpg")))
      hash = Hash.from_xml([@uploader].to_xml)
      expect(hash).to have_value([{"url"=>"/uploads/tmp/1369894322-345-1234-2255/test.jpg"}])
    end
  end

  describe '#to_s' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "should default to empty space" do
      expect(@uploader.to_s).to eq('')
    end

    it "should get the directory relative to public, prepending a slash" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.to_s).to eq('/uploads/tmp/1369894322-345-1234-2255/test.jpg')
    end

    it "should return file#url if available" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      allow(@uploader.file).to receive(:url).and_return('http://www.example.com/someurl.jpg')
      expect(@uploader.to_s).to eq('http://www.example.com/someurl.jpg')
    end
  end

end
