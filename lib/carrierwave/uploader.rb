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

    class Base

      attr_reader :file

      use CarrierWave::Uploader::Configurable
      use CarrierWave::Uploader::Callbacks
      use CarrierWave::Uploader::Proxy
      use CarrierWave::Uploader::Url
      use CarrierWave::Uploader::Mountable
      use CarrierWave::Uploader::Cache
      use CarrierWave::Uploader::Store
      use CarrierWave::Uploader::Remove
      use CarrierWave::Uploader::Processing
      use CarrierWave::Uploader::Versions
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

  end # Uploader
end # CarrierWave
