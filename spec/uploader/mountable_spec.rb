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

  describe '#index' do
    let(:model) { Class.new.send(:extend, CarrierWave::Mount) }
    let(:instance) { model.new }
    before do
      model.mount_uploaders(:images, uploader_class)
      instance.images = [stub_file('test.jpg'), stub_file('bork.txt')]
    end

    it "returns the current index in uploaders" do
      expect(instance.images.map(&:index)).to eq [0, 1]
    end
  end
end
