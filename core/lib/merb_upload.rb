# make sure we're running inside Merb
if defined?(Merb::Plugins)

  require 'fileutils'

  module Merb
    module Upload
      
      class << self
        attr_accessor :config
      end
      
      class UploadError < StandardError; end
      class NoFileError < UploadError; end
      class FormNotMultipart < UploadError; end
      class InvalidParameter < UploadError; end
      # Should be used by methods used as process callbacks.
      class ProcessingError < UploadError; end
    end
  end

  dir = File.dirname(__FILE__) / 'merb_upload'
  require dir / 'sanitized_file'
  require dir / 'uploader'
  require dir / 'mount'
  require dir / 'storage' / 'abstract'
  require dir / 'storage' / 'file'
  require dir / 'storage' / 's3'
  
  Merb::Upload.config = {
    :storage => :file,
    :use_cache => true,
    :store_dir => Merb.root / 'public' / 'uploads',
    :cache_dir => Merb.root / 'public' / 'uploads' / 'tmp',
    :storage_engines => {
      :file => Merb::Upload::Storage::File,
      :s3 => Merb::Upload::Storage::S3
    },
    :s3 => {
      :access => :public_read
    }
  }
  
  Merb.push_path(:uploader, Merb.root / "app" / "uploaders", "**/*.rb")
  
  Merb.add_generators File.dirname(__FILE__) / 'generators' / 'uploader_generator'

end