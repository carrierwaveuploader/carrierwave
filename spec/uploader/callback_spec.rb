require 'spec_helper'

describe CarrierWave::Uploader do

  it "should keep callbacks on different classes isolated" do
    default_before_callbacks = [
      :check_whitelist!,
      :check_blacklist!,
      :check_content_type_whitelist_pattern!,
      :check_content_type_blacklist_pattern!,
      :check_size!,
      :process!
    ]
    @uploader_class_1 = Class.new(CarrierWave::Uploader::Base)

    # First Uploader only has default before-callbacks
    expect(@uploader_class_1._before_callbacks[:cache]).to eq(default_before_callbacks)

    @uploader_class_2 = Class.new(CarrierWave::Uploader::Base)
    @uploader_class_2.before :cache, :before_cache_callback

    # Second Uploader defined with another callback
    expect(@uploader_class_2._before_callbacks[:cache]).to eq(default_before_callbacks + [:before_cache_callback])

    # Make sure the first Uploader doesn't inherit the same callback
    expect(@uploader_class_1._before_callbacks[:cache]).to eq(default_before_callbacks)
  end


end
