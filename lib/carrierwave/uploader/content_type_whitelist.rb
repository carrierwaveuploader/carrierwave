module CarrierWave
  module Uploader
    module ContentTypeWhitelist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_whitelist!
      end

      ##
      # Override this method in your uploader to provide a whitelist of files content types
      # which are allowed to be uploaded.
      # Not only strings but Regexp are allowed as well.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] a whitelist of content types which are allowed to be uploaded
      #
      # === Examples
      #
      #     def content_type_whitelist
      #       %w(text/json application/json)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def content_type_whitelist
      #       [/(text|application)\/json/]
      #     end
      #
      def content_type_whitelist; end

    private

      def check_content_type_whitelist!(new_file)
        return unless content_type_whitelist

        content_type = new_file.content_type
        if !whitelisted_content_type?(content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_whitelist_error", content_type: content_type, allowed_types: Array(content_type_whitelist).join(", "))
        end
      end

      def whitelisted_content_type?(content_type)
        Array(content_type_whitelist).any? do |item|
          item = Regexp.quote(item) if item.class != Regexp
          content_type =~ /#{item}/
        end
      end

    end # ContentTypeWhitelist
  end # Uploader
end # CarrierWave
