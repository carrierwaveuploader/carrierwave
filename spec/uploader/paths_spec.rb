require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }

  after { FileUtils.rm_rf(public_path) }

  describe '#root' do
    describe "default behavior" do
      before { CarrierWave.root = public_path }

      it "defaults to the current value of CarrierWave.root" do
        expect(uploader.root).to eq(public_path)
      end
    end
  end
end
