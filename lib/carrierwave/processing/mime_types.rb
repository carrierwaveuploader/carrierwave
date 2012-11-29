# encoding: utf-8

module CarrierWave

  ##
  # This module simplifies the use of the mime-types gem to intelligently
  # guess and set the content-type of a file. If you want to use this, you'll
  # need to require this file:
  #
  #     require 'carrierwave/processing/mime_types'
  #
  # And then include it in your uploader:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MimeTypes
  #     end
  #
  # You can now use the provided helper:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MimeTypes
  #
  #       process :set_content_type
  #     end
  #
  module MimeTypes
    extend ActiveSupport::Concern

    included do
      begin
        require "mime/types"
      rescue LoadError => e
        e.message << " (You may need to install the mime-types gem)"
        raise e
      end
    end

    module ClassMethods
      def set_content_type(override=false)
        process :set_content_type => override
      end
    end

    GENERIC_CONTENT_TYPES = %w[application/octet-stream binary/octet-stream]

    def generic_content_type?
      GENERIC_CONTENT_TYPES.include? file.content_type
    end

    ##
    # Changes the file content_type using the mime-types gem
    #
    # === Parameters
    #
    # [override (Boolean)] whether or not to override the file's content_type
    #                      if it is already set and not a generic content-type,
    #                      false by default
    #
    def set_content_type(override=false)
      if override || file.content_type.blank? || generic_content_type?
        new_content_type = ::MIME::Types.type_for(file.original_filename).first.to_s
        if file.respond_to?(:content_type=)
          file.content_type = new_content_type
        else
          file.instance_variable_set(:@content_type, new_content_type)
        end
      end
    rescue ::MIME::InvalidContentType => e
      raise CarrierWave::ProcessingError, I18n.translate(:"errors.messages.mime_types_processing_error", :e => e)
    end

  end # MimeTypes
end # CarrierWave
