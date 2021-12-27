# frozen_string_literal: true

require "rails/railtie"

module CarrierWave
  class Railtie < Rails::Railtie
    initializer "carrierwave.setup_paths" do |app|
      CarrierWave.root = Rails.root.join(Rails.public_path).to_s
      CarrierWave.base_path = ENV["RAILS_RELATIVE_URL_ROOT"]
      available_locales = Array(app.config.i18n.available_locales || [])
      if available_locales.blank? || available_locales.include?(:en)
        I18n.load_path.prepend(File.join(File.dirname(__FILE__), "..", "locale", "en.yml"))
      end
    end

    initializer "carrierwave.active_record" do
      ActiveSupport.on_load :active_record do
        require "carrierwave/orm/activerecord"
      end
    end

    config.before_eager_load do
      CarrierWave::Storage::Fog.eager_load
    end
  end
end
