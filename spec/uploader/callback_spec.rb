require 'spec_helper'

describe CarrierWave::Uploader do
  describe "callback isolation" do
    let(:default_before_callbacks) do
      [
        :check_extension_allowlist!,
        :check_extension_denylist!,
        :check_content_type_allowlist!,
        :check_content_type_denylist!,
        :check_size!,
        :process!
      ]
    end

    let(:uploader_class_1) { Class.new(CarrierWave::Uploader::Base) }
    let(:uploader_class_2) { Class.new(CarrierWave::Uploader::Base) }

    before { uploader_class_2.before(:cache, :before_cache_callback) }

    it { expect(uploader_class_1._before_callbacks[:cache]).to eq(default_before_callbacks) }


    it { expect(uploader_class_2._before_callbacks[:cache]).to eq(default_before_callbacks + [:before_cache_callback]) }

    it "doesn't inherit the uploader 2 callback" do
      expect(uploader_class_1._before_callbacks[:cache]).to eq(default_before_callbacks)
    end
  end
end
