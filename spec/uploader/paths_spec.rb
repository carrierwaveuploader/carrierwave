# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    @root = CarrierWave.root
    CarrierWave.root = nil
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
    CarrierWave.root = @root
  end

  describe '#root' do
    it "should default to the current value of CarrierWave.root" do
      expect(@uploader.root).to be_nil
      CarrierWave.root = public_path
      expect(@uploader.root).to eq(public_path)
    end
  end

end
