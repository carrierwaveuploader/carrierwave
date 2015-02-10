# encoding: utf-8

module CarrierWave
  ##
  # This module simplifies the use of ruby-filemagic gem to intelligently
  # and correctly guess and set the content-type of a file. If you want 
  # to use this, you'll need to require this file:
  #
  #    require 'carrierwave/processing/magic_mime_types'
  #
  # And then include it in your uploader:
  #
  #   class MyUploader < CarrierWave::Uploader::Base
  #     include CarrierWave::MagicMimeTypes
  #   end
  #
  # You can use the provided helper:
  #
  #   class MyUploader < CarrierWave::Uploader::Base
  #     include CarrierWave::MagicMimeTypes
  #
  #     process :set_content_type
  #   end
  module MagicMimeTypes
    extend ActiveSupport::Concern

    included do
      begin
        require "filemagic"
      rescue LoadError => e
        e.message << " (You may need to install the ruby-filemagic gem)"
        raise e
      end
    end

    module ClassMethods
      def set_content_type(override=false)
        process :set_content_type => override
      end
    end

    ##
    # Changes the file content_type using the ruby-filemagic gem
    #
    # === Parameters
    #
    # [override (Boolean)] wheter or not to override the file's content_type
    #                      if it is already set, false by default
    def set_content_type(override=false)
      if override || file.content_type.blank?
        File.open(file.path) do |fd|
          data = fd.read(1024) || ""
          new_content_type = filemagic.buffer(data)
          if file.respond_to?(:content_type=)
            file.content_type = new_content_type
          else
            file.instance_variable_set(:@content_type, new_content_type)
          end
        end
      end
    end

    ##
    # FileMagic object with the MAGIC_MIME_TYPE flag set
    #
    # @return [FileMagic] a filemagic object
    def filemagic
      @filemagic ||= FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
    end
  end
end
