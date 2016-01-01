module CarrierWave
  module Uploader
    module ContentTypeWhitelist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_whitelist_pattern!
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
      #     def content_type_whitelist_pattern
      #       /(text|application)\/json/
      #     end
      #
      def content_type_whitelist_pattern; end

    private

      def check_content_type_whitelist_pattern!(new_file)
        content_type = new_file.content_type
        if content_type_whitelist_pattern && !whitelisted_content_type?(content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_whitelist_error", content_type: content_type)
        end
      end

      def whitelisted_content_type?(content_type)
        content_type.match(content_type_whitelist_pattern)
      end

    end # ContentTypeWhitelist
  end # Uploader
end # CarrierWave
