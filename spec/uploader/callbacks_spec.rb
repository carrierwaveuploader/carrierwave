require 'spec_helper'

describe CarrierWave::Uploader do
  describe 'callbacks' do 
    before do
      @uploader_without_callbacks = Class.new(CarrierWave::Uploader::Base)
      @uploader_with_callbacks    = Class.new(CarrierWave::Uploader::Base) do 
        before :cache, :before_cache 
        after  :cache, :after_cache 
      end
    end

    it 'should only be inherrited' do 
      @uploader_without_callbacks._before_callbacks[:cache].should == CarrierWave::Uploader::Base._before_callbacks[:cache]
      @uploader_without_callbacks._after_callbacks[:cache].should == CarrierWave::Uploader::Base._after_callbacks[:cache]

      @uploader_without_callbacks._before_callbacks[:cache].should_not == @uploader_with_callbacks._before_callbacks[:cache]
      @uploader_without_callbacks._after_callbacks[:cache].should_not == @uploader_with_callbacks._after_callbacks[:cache]
    end
  end
end
