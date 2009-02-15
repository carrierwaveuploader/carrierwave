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

dir = File.join(File.dirname(__FILE__), 'merb_upload')

require File.join(dir, 'sanitized_file')
require File.join(dir, 'uploader')
require File.join(dir, 'mount')
require File.join(dir, 'storage', 'abstract')
require File.join(dir, 'storage', 'file')
require File.join(dir, 'storage', 's3')

Merb::Upload.config = {
  :storage => :file,
  :use_cache => true,
  :storage_engines => {
    :file => Merb::Upload::Storage::File,
    :s3 => Merb::Upload::Storage::S3
  },
  :s3 => {
    :access => :public_read
  }
}

if defined?(Merb::Plugins)
  Merb::Upload.config[:public] = Merb.dir_for(:public)
  Merb::Upload.config[:store_dir] = Merb.root / 'public' / 'uploads'
  Merb::Upload.config[:cache_dir] = Merb.root / 'public' / 'uploads' / 'tmp'
  
  Merb.push_path(:uploader, Merb.root / "app" / "uploaders", "**/*.rb")
  
  Merb.add_generators File.dirname(__FILE__) / 'generators' / 'uploader_generator'
end