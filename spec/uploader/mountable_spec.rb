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

  describe '#model' do
    it "should be remembered from initialization" do
      model = double('a model object')
      @uploader = @uploader_class.new(model)
      expect(@uploader.model).to eq(model)
    end
  end

  describe '#mounted_as' do
    it "should be remembered from initialization" do
      model = double('a model object')
      @uploader = @uploader_class.new(model, :llama)
      expect(@uploader.model).to eq(model)
      expect(@uploader.mounted_as).to eq(:llama)
    end
  end

end
