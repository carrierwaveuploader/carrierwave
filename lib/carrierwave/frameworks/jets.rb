# frozen_string_literal: true

gem "jets", ">= 3.0.0"

module CarrierWave
  class Turbine < Jets::Turbine
    initializer "carrierwave.setup_paths" do |_app|
      CarrierWave.root = Jets.root.to_s
      CarrierWave.tmp_path = "/tmp/carrierwave"
      CarrierWave.configure do |config|
        config.cache_dir = "/tmp/carrierwave/uploads/tmp"
      end
    end

    initializer "carrierwave.active_record" do
      ActiveSupport.on_load :active_record do
        require "carrierwave/orm/activerecord"
      end
    end
  end
end
