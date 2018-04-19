module CarrierWave
  module Uploader

    ##
    # This modules validates the content type of a file with the use of
    # ruby-filemagic gem and a blacklist regular expression. If you want
    # to use this, you'll need to require this file:
    #
    #   require 'carrierwave/uploader/magic_mime_blacklist'
    #
    # And then include it in your uploader:
    #
    #   class MyUploader < CarrierWave::Uploader::Base
    #     include CarrierWave::Uploader::MagicMimeBlacklist
    #
    #     def blacklist_mime_type_pattern
    #       /image\//
    #     end
    #   end
    #
    module MagicMimeBlacklist
      extend ActiveSupport::Concern

      included do
        begin
          require "filemagic"
        rescue LoadError => e
          e.message << " (You may need to install the ruby-filemagic gem)"
          raise e
        end

        before :cache, :check_blacklist_pattern!
      end

      ##
      # Override this method in your uploader to provide a black list pattern (regexp)
      # of content-types which are prohibited to be uploaded.
      # Compares the file's content-type.
      #
      # === Returns
      #
      # [Regexp] a black list regexp to match the content_type
      #
      # === Examples
      #
      #     def blacklist_mime_type_pattern
      #       /(text|application)\/json/
      #     end
      #
      def blacklist_mime_type_pattern; end

    private

      def check_blacklist_pattern!(new_file)
        return if blacklist_mime_type_pattern.nil?

        content_type = extract_content_type(new_file)

        if content_type.match(blacklist_mime_type_pattern)
          raise CarrierWave::IntegrityError,
            I18n.translate(:"errors.messages.mime_type_pattern_black_list_error",
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

    end # MagicMimeblackList
  end # Uploader
end # CarrierWave
