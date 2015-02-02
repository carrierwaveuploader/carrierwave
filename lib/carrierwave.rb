# encoding: utf-8

require 'fileutils'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

module CarrierWave
  class << self
    attr_accessor :root, :base_path
    attr_writer :tmp_path

    def configure(&block)
      CarrierWave::Uploader::Base.configure(&block)
    end

    def clean_cached_files!(seconds = 60 * 60 * 24)
      CarrierWave::Uploader::Base.clean_cached_files!(seconds)
    end

    def tmp_path
      @tmp_path ||= File.expand_path(File.join('..', 'tmp'), root)
    end
  end
end

if defined?(Merb)

  CarrierWave.root = Merb.dir_for(:public)
  Merb::BootLoader.before_app_loads do
    # Setup path for uploaders and load all of them before classes are loaded
    Merb.push_path(:uploaders, Merb.root / 'app' / 'uploaders', '*.rb')
    Dir.glob(File.join(Merb.load_paths[:uploaders])).each { |f| require f }
  end

elsif defined?(Rails)

  module CarrierWave
    class Railtie < Rails::Railtie
      initializer 'carrierwave.setup_paths' do |app|
        CarrierWave.root = Rails.root.join(Rails.public_path).to_s
        CarrierWave.base_path = ENV['RAILS_RELATIVE_URL_ROOT']

        pattern = CarrierWave::Railtie.locales_pattern_from app.config.i18n.available_locales

        files = Dir[File.join(File.dirname(__FILE__), 'carrierwave', 'locale', "#{pattern}.yml")]
        # Loads the Carrierwave locale files before the Rails application locales
        # letting the Rails application overrite the carrierwave locale defaults
        I18n.load_path = files.concat I18n.load_path
      end

      initializer 'carrierwave.active_record' do
        ActiveSupport.on_load :active_record do
          require 'carrierwave/orm/activerecord'
        end
      end

      protected

      def self.locales_pattern_from(args)
        array = Array(args || [])
        array.blank? ? '*' : "{#{array.join ','}}"
      end
    end
  end

elsif defined?(Sinatra)
  if defined?(Padrino) && defined?(PADRINO_ROOT)
    CarrierWave.root = File.join(PADRINO_ROOT, 'public')
  else

    CarrierWave.root = if Sinatra::Application.respond_to?(:public_folder)
                         # Sinatra >= 1.3
                         Sinatra::Application.public_folder
                       else
                         # Sinatra < 1.3
                         Sinatra::Application.public
    end
  end
end

require 'carrierwave/utilities'
require 'carrierwave/error'
require 'carrierwave/sanitized_file'
require 'carrierwave/mounter'
require 'carrierwave/mount'
require 'carrierwave/processing'
require 'carrierwave/version'
require 'carrierwave/storage'
require 'carrierwave/uploader'
require 'carrierwave/compatibility/paperclip'
require 'carrierwave/test/matchers'
