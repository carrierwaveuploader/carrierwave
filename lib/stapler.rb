require 'fileutils'

module Stapler
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

dir = File.join(File.dirname(__FILE__), 'stapler')

require File.join(dir, 'sanitized_file')
require File.join(dir, 'uploader')
require File.join(dir, 'mount')
require File.join(dir, 'storage', 'abstract')
require File.join(dir, 'storage', 'file')
require File.join(dir, 'storage', 's3')

Stapler.config = {
  :storage => :file,
  :use_cache => true,
  :storage_engines => {
    :file => Stapler::Storage::File,
    :s3 => Stapler::Storage::S3
  },
  :s3 => {
    :access => :public_read
  }
}

if defined?(Merb::Plugins)
  Stapler.config[:public] = Merb.dir_for(:public)
  Stapler.config[:store_dir] = Merb.root / 'public' / 'uploads'
  Stapler.config[:cache_dir] = Merb.root / 'public' / 'uploads' / 'tmp'
  
  orm_path = File.dirname(__FILE__) / 'stapler' / 'orm' / Merb.orm
  require orm_path if File.exist?(orm_path + '.rb')
  
  Merb.push_path(:uploader, Merb.root / "app" / "uploaders", "**/*.rb")
  
  Merb.add_generators File.dirname(__FILE__) / 'generators' / 'uploader_generator'
end

if defined?(Rails)
  Stapler.config[:public] = File.join(Rails.root, 'public')
  Stapler.config[:store_dir] = File.join(Rails.root, 'public', 'uploads')
  Stapler.config[:cache_dir] = File.join(Rails.root, 'public', 'uploads', 'tmp')
  
  require File.join(File.dirname(__FILE__), "stapler", "orm", 'activerecord')
  
  # FIXME: this is broken? It works fine when I add load paths in environment.rb :S
  Rails.configuration.load_paths << File.join(Rails.root, "app", "uploaders")
end