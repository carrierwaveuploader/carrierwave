# encoding: utf-8

require 'fileutils'
require 'carrierwave/core_ext/blank'
require 'carrierwave/core_ext/module_setup'
require 'carrierwave/core_ext/inheritable_attributes'

module CarrierWave

  VERSION = "0.4.0"

  class << self
    def configure(&block)
      CarrierWave::Uploader::Base.configure(&block)
    end
  end

  class UploadError < StandardError; end
  class IntegrityError < UploadError; end
  class InvalidParameter < UploadError; end
  class ProcessingError < UploadError; end

  autoload :SanitizedFile, 'carrierwave/sanitized_file'
  autoload :Mount, 'carrierwave/mount'
  autoload :RMagick, 'carrierwave/processing/rmagick'
  autoload :ImageScience, 'carrierwave/processing/image_science'
  autoload :MiniMagick, 'carrierwave/processing/mini_magick'

  module Storage
    autoload :Abstract, 'carrierwave/storage/abstract'
    autoload :File, 'carrierwave/storage/file'
    autoload :S3, 'carrierwave/storage/s3'
    autoload :GridFS, 'carrierwave/storage/grid_fs'
  end

  module Uploader
    autoload :Base, 'carrierwave/uploader'
    autoload :Cache, 'carrierwave/uploader/cache'
    autoload :Store, 'carrierwave/uploader/store'
    autoload :Callbacks, 'carrierwave/uploader/callbacks'
    autoload :Processing, 'carrierwave/uploader/processing'
    autoload :Versions, 'carrierwave/uploader/versions'
    autoload :Remove, 'carrierwave/uploader/remove'
    autoload :ExtensionWhitelist, 'carrierwave/uploader/extension_whitelist'
    autoload :DefaultUrl, 'carrierwave/uploader/default_url'
    autoload :Proxy, 'carrierwave/uploader/proxy'
    autoload :Url, 'carrierwave/uploader/url'
    autoload :Mountable, 'carrierwave/uploader/mountable'
    autoload :Configuration, 'carrierwave/uploader/configuration'
  end

  module Compatibility
    autoload :Paperclip, 'carrierwave/compatibility/paperclip'
  end

  module Test
    autoload :Matchers, 'carrierwave/test/matchers'
  end

end

if defined?(Merb)
  CarrierWave.configure do |config|
    config.root = Merb.dir_for(:public)
  end
  Merb::BootLoader.before_app_loads do
    # Setup path for uploaders and load all of them before classes are loaded
    Merb.push_path(:uploaders, Merb.root / 'app' / 'uploaders', '*.rb')
    Dir.glob(File.join(Merb.load_paths[:uploaders])).each {|f| require f }
  end
elsif defined?(Rails)
  CarrierWave.configure do |config|
    config.root = File.join(Rails.root, 'public')
  end
  ActiveSupport::Dependencies.load_paths << File.join(Rails.root, "app", "uploaders")
elsif defined?(Sinatra)
  CarrierWave.configure do |config|
    config.root = Sinatra::Application.public
  end
end


require File.join(File.dirname(__FILE__), "carrierwave", "orm", 'activerecord') if defined?(ActiveRecord)
require File.join(File.dirname(__FILE__), "carrierwave", "orm", 'datamapper') if defined?(DataMapper)
require File.join(File.dirname(__FILE__), "carrierwave", "orm", 'sequel') if defined?(Sequel)
require File.join(File.dirname(__FILE__), "carrierwave", "orm", "mongomapper") if defined?(MongoMapper)
