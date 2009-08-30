# encoding: utf-8

require 'fileutils'
require 'carrierwave/core_ext/blank'
require 'carrierwave/core_ext/module_setup'
require 'carrierwave/core_ext/inheritable_attributes'

module CarrierWave

  VERSION = "0.3.4"

  class << self
    attr_accessor :config, :logger

    def logger
      return @logger if @logger
      require 'logger'
      @logger = Logger.new(STDOUT)
    end

    ##
    # Generates a unique cache id for use in the caching system
    #
    # === Returns
    #
    # [String] a cache id in the format YYYYMMDD-HHMM-PID-RND
    #
    def generate_cache_id
      Time.now.strftime('%Y%m%d-%H%M') + '-' + Process.pid.to_s + '-' + ("%04d" % rand(9999))
    end
  end

  class UploadError < StandardError; end
  class NoFileError < UploadError; end
  class FormNotMultipart < UploadError
    def message
      "You tried to assign a String or a Pathname to an uploader, for security reasons, this is not allowed.\n\n If this is a file upload, please check that your upload form is multipart encoded."
    end
  end
  class IntegrityError < UploadError; end
  class InvalidParameter < UploadError; end
  # Should be used by methods used as process callbacks.
  class ProcessingError < UploadError; end

  autoload :SanitizedFile, 'carrierwave/sanitized_file'
  autoload :Mount, 'carrierwave/mount'
  autoload :RMagick, 'carrierwave/processing/rmagick'
  autoload :ImageScience, 'carrierwave/processing/image_science'

  module Storage
    autoload :Abstract, 'carrierwave/storage/abstract'
    autoload :File, 'carrierwave/storage/file'
    autoload :S3, 'carrierwave/storage/s3'
  end

  module Uploader
    autoload :Base, 'carrierwave/uploader'
    autoload :Cache, 'carrierwave/uploader/cache'
    autoload :Store, 'carrierwave/uploader/store'
    autoload :Callbacks, 'carrierwave/uploader/callbacks'
    autoload :Processing, 'carrierwave/uploader/processing'
    autoload :Versions, 'carrierwave/uploader/versions'
    autoload :Remove, 'carrierwave/uploader/remove'
    autoload :Paths, 'carrierwave/uploader/paths'
    autoload :ExtensionWhitelist, 'carrierwave/uploader/extension_whitelist'
    autoload :DefaultPath, 'carrierwave/uploader/default_path'
    autoload :Proxy, 'carrierwave/uploader/proxy'
    autoload :Url, 'carrierwave/uploader/url'
    autoload :Mountable, 'carrierwave/uploader/mountable'
  end

  module Compatibility
    autoload :Paperclip, 'carrierwave/compatibility/paperclip'
  end

  module Test
    autoload :Matchers, 'carrierwave/test/matchers'
  end

end

CarrierWave.config = {
  :permissions => 0644,
  :storage => :file,
  :use_cache => true,
  :storage_engines => {
    :file => "CarrierWave::Storage::File",
    :s3 => "CarrierWave::Storage::S3"
  },
  :s3 => {
    :access => :public_read
  },
  :store_dir => 'uploads',
  :cache_dir => 'uploads/tmp',
  :cache_to_cache_dir => true,
  :mount => {
    :ignore_integrity_errors => true,
    :ignore_processing_errors => true,
    :validate_integrity => true,
    :validate_processing => true
  }
}

if defined?(Merb::Plugins)
  CarrierWave.config[:root] = Merb.root
  CarrierWave.config[:public] = Merb.dir_for(:public)

  Merb::BootLoader.before_app_loads do
    # Set logger
    CarrierWave.logger ||= Merb.logger
    # Setup path for uploaders and load all of them before classes are loaded
    Merb.push_path(:uploaders, Merb.root / 'app' / 'uploaders', '*.rb')
    Dir.glob(File.join(Merb.load_paths[:uploaders])).each {|f| require f }
  end

  orm_path = File.dirname(__FILE__) / 'carrierwave' / 'orm' / Merb.orm
  require orm_path if File.exist?(orm_path + '.rb')

  Merb.add_generators File.dirname(__FILE__) / 'generators' / 'uploader_generator'

elsif defined?(Rails)
  begin
    CarrierWave.logger = Rails.logger
  rescue
    # Rails < 2.1
    CarrierWave.logger = RAILS_DEFAULT_LOGGER
  end
  CarrierWave.config[:root] = Rails.root
  CarrierWave.config[:public] = File.join(Rails.root, 'public')

  require File.join(File.dirname(__FILE__), "carrierwave", "orm", 'activerecord')

  ActiveSupport::Dependencies.load_paths << File.join(Rails.root, "app", "uploaders")

elsif defined?(Sinatra)

  CarrierWave.config[:root] = Sinatra::Application.root
  CarrierWave.config[:public] = Sinatra::Application.public

end

# MongoMapper is framework agnostic so we could need this in any environment.
if defined?(MongoMapper)
  require File.join(File.dirname(__FILE__), "carrierwave", "orm", "mongomapper")
end
