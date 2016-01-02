module CarrierWave
  module Uploader

    ##
    # This modules validates the content type of a file with the use of
    # ruby-filemagic gem and a whitelist regular expression. If you want
    # to use this, you'll need to require this file:
    #
    #   require 'carrierwave/uploader/magic_mime_whitelist'
    #
    # And then include it in your uploader:
    #
    #   class MyUploader < CarrierWave::Uploader::Base
    #     include CarrierWave::Uploader::MagicMimeWhitelist
    #
    #     def whitelist_mime_type_pattern
    #       /image\//
    #     end
    #   end
    #
    module MagicMimeWhitelist
      extend ActiveSupport::Concern

      included do
        begin
          require "filemagic"
        rescue LoadError => e
          e.message << " (You may need to install the ruby-filemagic gem)"
          raise e
        end

        before :cache, :check_whitelist_pattern!
      end

      ##
      # Override this method in your uploader to provide a white list pattern (regexp)
      # of content-types which are allowed to be uploaded.
      # Compares the file's content-type.
      #
      # === Returns
      #
      # [Regexp] a white list regexp to match the content_type
      #
      # === Examples
      #
      #     def whitelist_mime_type_pattern
      #       /(text|application)\/json/
      #     end
      #
      def whitelist_mime_type_pattern; end

    private

      def check_whitelist_pattern!(new_file)
        return if whitelist_mime_type_pattern.nil?

        content_type = extract_content_type(new_file)

        if !content_type.match(whitelist_mime_type_pattern)
          raise CarrierWave::IntegrityError,
            I18n.translate(:"errors.messages.mime_type_pattern_white_list_error",
                           :content_type => content_type)
        end
      end

      ##
      # Extracts the content type of the given file
      #
      # === Returns
      #
      # [String] the extracted content type
      #
      def extract_content_type(new_file)
        content_type = nil

        File.open(new_file.path) do |fd|
          data = fd.read(1024) || ""
          content_type = filemagic.buffer(data)
        end

        content_type
      end

    ##
    # FileMagic object with the MAGIC_MIME_TYPE flag set
    #
    # @return [FileMagic] a filemagic object
      def filemagic
        @filemagic ||= FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
      end

    end # MagicMimeWhiteList
  end # Uploader
end # CarrierWave
