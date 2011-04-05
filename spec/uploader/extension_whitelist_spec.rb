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

    it "should not raise an integrity error if there is no white list" do
      @uploader.stub!(:extension_white_list).and_return(nil)
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end

    it "should not raise an integrity error if there is a white list and the file is on it" do
      @uploader.stub!(:extension_white_list).and_return(%w(jpg gif png))
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an integrity error if there is a white list and the file is not on it" do
      @uploader.stub!(:extension_white_list).and_return(%w(txt doc xls))
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an integrity error if there is a white list and the file is not on it, using start of string matcher" do
      @uploader.stub!(:extension_white_list).and_return(%w(txt))
      running {
        @uploader.cache!(File.open(file_path('bork.ttxt')))
      }.should raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an integrity error if there is a white list and the file is not on it, using end of string matcher" do
      @uploader.stub!(:extension_white_list).and_return(%w(txt))
      running {
        @uploader.cache!(File.open(file_path('bork.txtt')))
      }.should raise_error(CarrierWave::IntegrityError)
    end

    it "should compare white list in a case insensitive manner" do
      @uploader.stub!(:extension_white_list).and_return(%w(jpg gif png))
      running {
        @uploader.cache!(File.open(file_path('case.JPG')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end

    it "should ignore case of extensions provided by white list" do
      @uploader.stub!(:extension_white_list).and_return(%w(JPG GIF PNG))
      running {
        @uploader.cache!(File.open(file_path('test.jpg')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end

    it "should accept and check regular expressions" do
      @uploader.stub!(:extension_white_list).and_return([/jpe?g/, 'gif', 'png'])
      running {
        @uploader.cache!(File.open(file_path('test.jpeg')))
      }.should_not raise_error(CarrierWave::IntegrityError)
    end
  end

end
