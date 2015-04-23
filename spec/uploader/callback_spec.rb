# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  it "should keep callbacks on different classes isolated" do
    @uploader_class_1 = Class.new(CarrierWave::Uploader::Base)

    # First Uploader only has default before-callback
    expect(@uploader_class_1._before_callbacks[:cache]).to eq([:check_whitelist!, :check_blacklist!, :check_size!, :process!])

    @uploader_class_2 = Class.new(CarrierWave::Uploader::Base)
    @uploader_class_2.before :cache, :before_cache_callback

    # Second Uploader defined with another callback
    expect(@uploader_class_2._before_callbacks[:cache]).to eq([:check_whitelist!, :check_blacklist!, :check_size!, :process!, :before_cache_callback])

    # Make sure the first Uploader doesn't inherit the same callback
    expect(@uploader_class_1._before_callbacks[:cache]).to eq([:check_whitelist!, :check_blacklist!, :check_size!, :process!])
  end


end
