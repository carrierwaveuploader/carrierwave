require 'fileutils'

module CarrierWave
  class << self
    attr_accessor :config, :logger
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
  autoload :Uploader, 'carrierwave/uploader'
  autoload :Mount, 'carrierwave/mount'
  autoload :RMagick, 'carrierwave/processing/rmagick'
  autoload :ImageScience, 'carrierwave/processing/image_science'

  module Storage
    autoload :Abstract, 'carrierwave/storage/abstract'
    autoload :File, 'carrierwave/storage/file'
    autoload :S3, 'carrierwave/storage/s3'
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
