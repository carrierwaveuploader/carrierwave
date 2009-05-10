require 'carrierwave/uploader/cache'
require 'carrierwave/uploader/store'
require 'carrierwave/uploader/processing'
require 'carrierwave/uploader/versions'
require 'carrierwave/uploader/remove'
require 'carrierwave/uploader/configurable'
require 'carrierwave/uploader/proxy'
require 'carrierwave/uploader/url'

module CarrierWave

  ##
  # An uploader is a class that allows you to easily handle the caching and storage of
  # uploaded files. Please refer to the README for configuration options.
  #
  # Once you have an uploader you can use it in isolation:
  #
  #     my_uploader = MyUploader.new
  #     my_uploader.cache!(File.open(path_to_file))
  #     my_uploader.retrieve_from_store!('monkey.png')
  #
  # Alternatively, you can mount it on an ORM or other persistence layer, with
  # +CarrierWave::Mount#mount_uploader+. There are extensions for activerecord and datamapper
  # these are *very* simple (they are only a dozen lines of code), so adding your own should
  # be trivial.
  #
  module Uploader

    include CarrierWave::Uploader::Configurable
    include CarrierWave::Uploader::Proxy
    include CarrierWave::Uploader::Url
    include CarrierWave::Uploader::Cache
    include CarrierWave::Uploader::Store
    include CarrierWave::Uploader::Remove
    include CarrierWave::Uploader::Processing
    include CarrierWave::Uploader::Versions

    def self.append_features(base) #:nodoc:
      super
      base.extend(CarrierWave::Uploader::Store::ClassMethods)
      base.extend(CarrierWave::Uploader::Processing::ClassMethods)
      base.extend(CarrierWave::Uploader::Versions::ClassMethods)
    end
    
    ##
    # Generates a unique cache id for use in the caching system
    #
    # === Returns
    #
    # [String] a cache id in the format YYYYMMDD-HHMM-PID-RND
    #
    def self.generate_cache_id
      Time.now.strftime('%Y%m%d-%H%M') + '-' + Process.pid.to_s + '-' + ("%04d" % rand(9999))
    end

    attr_reader :file, :model, :mounted_as

    ##
    # If a model is given as the first parameter, it will stored in the uploader, and
    # available throught +#model+. Likewise, mounted_as stores the name of the column
    # where this instance of the uploader is mounted. These values can then be used inside
    # your uploader.
    #
    # If you do not wish to mount your uploaders with the ORM extensions in -more then you
    # can override this method inside your uploader. Just be sure to call +super+
    #
    # === Parameters
    #
    # [model (Object)] Any kind of model object
    # [mounted_as (Symbol)] The name of the column where this uploader is mounted
    #
    # === Examples
    #
    #     class MyUploader
    #       include CarrierWave::Uploader
    #
    #       def store_dir
    #         File.join('public', 'files', mounted_as, model.permalink)
    #       end
    #     end
    #
    def initialize(model=nil, mounted_as=nil)
      @model = model
      @mounted_as = mounted_as
      if default_path
        @file = CarrierWave::SanitizedFile.new(File.expand_path(default_path, public))
        def @file.blank?; true; end
      end
    end

  end # Uploader
end # CarrierWave
