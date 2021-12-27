# frozen_string_literal: true

require "fileutils"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/core_ext/class/attribute"
require "active_support/concern"

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
      @tmp_path ||= File.expand_path(File.join("..", "tmp"), root)
    end
  end
end

require "carrierwave/utilities"
require "carrierwave/error"
require "carrierwave/sanitized_file"
require "carrierwave/mounter"
require "carrierwave/mount"
require "carrierwave/processing"
require "carrierwave/version"
require "carrierwave/storage"
require "carrierwave/uploader"

require "carrierwave/frameworks/railtie" if defined?(Rails)
