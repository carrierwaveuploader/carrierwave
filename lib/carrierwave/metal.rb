require "carrierwave/uploader/configuration"
require "carrierwave/uploader/callbacks"
require "carrierwave/uploader/proxy"
require "carrierwave/uploader/url"
require "carrierwave/uploader/mountable"
require "carrierwave/uploader/cache"
require "carrierwave/uploader/store"
require "carrierwave/uploader/remove"
require "carrierwave/uploader/processing"
require "carrierwave/uploader/default_url"

module CarrierWave

  ##
  # See CarrierWave::Uploader::Metal
  #
  module Uploader

    ##
    # An uploader class that is stripped from all extra hooks and proccess.
    # This class can be used when the file are being generated internally or the input is already trusted and sanitized
    #
    class Metal
      attr_reader :file

      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Proxy
      include CarrierWave::Uploader::Url
      include CarrierWave::Uploader::Mountable
      include CarrierWave::Uploader::Cache
      include CarrierWave::Uploader::Store
      include CarrierWave::Uploader::Processing
      include CarrierWave::Uploader::Remove
      include CarrierWave::Uploader::DefaultUrl
    end # Base

  end
end
