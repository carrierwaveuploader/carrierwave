require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) do
    Class.new(CarrierWave::Uploader::Base).tap do |c|
      c.version :thumb
    end
  end
  let(:uploader) { uploader_class.new }

  after { FileUtils.rm_rf(public_path) }

  describe '#serializable_hash' do
    it "has string key for version value" do
      expect(uploader.serializable_hash.keys).to include('thumb')
    end
  end
end
