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

  describe '#cache!' do

    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should not raise an integrity error if there is no range specified" do
      @uploader.stub!(:size_range).and_return(nil)
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an integrity error if there is a size range and file has size less than minimum" do
      @uploader.stub!(:size_range).and_return(2097152..4194304)
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an integrity error if there is a size range and file has size more than maximum" do
      @uploader.stub!(:size_range).and_return(0..10)
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should raise_error(CarrierWave::IntegrityError)
    end

    it "should not raise an integrity error if there is a size range the file is not on it" do
      @uploader.stub!(:size_range).and_return(0..50)
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end
  end
end
