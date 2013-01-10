# encoding: utf-8

module CarrierWave

  ##
  # This module uses ruby-filemagic gem to intelligently
  # guess and set the content-type of a file. It uses libmagic(man 3 libmagic)
  # If you want to use this, you'll need to require this file:
  #
  #     require 'carrierwave/processing/magic_mime_types'
  #
  # And then include it in your uploader:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MagicMimeTypes
  #     end
  #
  # After that you can use the provided helper:
  #
  #     class MyUploader < CarrierWave::Uploader::Base
  #       include CarrierWave::MagicMimeTypes
  #
  #       process :set_magic_content_type
  #     end
  #
  module MagicMimeTypes
    include CarrierWave::GenericContentTypes
    extend ActiveSupport::Concern

    included do
      begin
        require 'filemagic'
      rescue LoadError => e
        e.message << ' (You may need to install the ruby-filemagic gem)'
        raise e
      end
    end

    module ClassMethods
      def set_magic_content_type(override=false)
        process :set_magic_content_type => override
      end
    end

    ##
    # Changes the file content_type using the ruby-filemagic gem
    #
    def set_magic_content_type(override=false)
      if override || file.content_type.blank? || generic_content_type?(file.content_type)
        new_content_type = FileMagic.new(FileMagic::MAGIC_MIME).file( file.path ).split(';').first

        if file.respond_to?(:content_type=)
          file.content_type = new_content_type
        else
          file.instance_variable_set(:@content_type, new_content_type)
        end
      end
    rescue ::Exception => e
      raise CarrierWave::ProcessingError, I18n.translate(:"errors.messages.magic_mime_types_processing_error", :e => e)
    end

  end # MagicMimeTypes
end # CarrierWave
