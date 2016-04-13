require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }

  after { FileUtils.rm_rf(public_path) }

  describe '#model' do
    let(:model) { double('a model object') }
    let(:uploader) { uploader_class.new(model) }

    it "is remembered from initialization" do
      expect(uploader.model).to eq(model)
    end
  end

  describe '#mounted_as' do
    let(:model) { double('a model object') }
    let(:uploader) { uploader_class.new(model, :llama) }

    it "is remembered from initialization" do
      expect(uploader.mounted_as).to eq(:llama)
    end
  end
end
