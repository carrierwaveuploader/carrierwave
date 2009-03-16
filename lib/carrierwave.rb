require 'fileutils'

module CarrierWave
  class << self
    attr_accessor :config
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
end

dir = File.join(File.dirname(__FILE__), 'carrierwave')

require File.join(dir, 'sanitized_file')
require File.join(dir, 'uploader')
require File.join(dir, 'mount')
require File.join(dir, 'storage', 'abstract')
require File.join(dir, 'storage', 'file')
require File.join(dir, 'storage', 's3')

CarrierWave.config = {
  :storage => :file,
  :use_cache => true,
  :storage_engines => {
    :file => CarrierWave::Storage::File,
    :s3 => CarrierWave::Storage::S3
  },
  :s3 => {
    :access => :public_read
  },
  :store_dir => 'uploads',
  :cache_dir => 'uploads/tmp',
  :mount => {
    :ignore_integrity_errors => true
  }
}

if defined?(Merb)
  CarrierWave.config[:root] = Merb.root
  CarrierWave.config[:public] = Merb.dir_for(:public)

  orm_path = File.dirname(__FILE__) / 'carrierwave' / 'orm' / Merb.orm
  require orm_path if File.exist?(orm_path + '.rb')

  Merb.push_path(:uploader, Merb.root / "app" / "uploaders")

  Merb.add_generators File.dirname(__FILE__) / 'generators' / 'uploader_generator'
end

if defined?(Rails)
  CarrierWave.config[:root] = Rails.root
  CarrierWave.config[:public] = File.join(Rails.root, 'public')

  require File.join(File.dirname(__FILE__), "carrierwave", "orm", 'activerecord')

  ActiveSupport::Dependencies.load_paths << File.join(Rails.root, "app", "uploaders")
end

if defined?(Sinatra)
  CarrierWave.config[:root] = Sinatra::Application.root
  CarrierWave.config[:public] = Sinatra::Application.public
end
