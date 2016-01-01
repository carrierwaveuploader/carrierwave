module CarrierWave
  module Uploader
    module ContentTypeBlacklist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_blacklist_pattern!
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
      #     def content_type_blacklist_pattern
      #       /(text|application)\/json/
      #     end
      #
      def content_type_blacklist_pattern; end

    private

      def check_content_type_blacklist_pattern!(new_file)
        content_type = new_file.content_type
        if content_type_blacklist_pattern && content_type.match(content_type_blacklist_pattern)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_blacklist_error", content_type: content_type)
        end
      end

      def blacklisted_content_type?(content_type)
        content_type.match(content_type_blacklist_pattern)
      end

    end # ContentTypeBlacklist
  end # Uploader
end # CarrierWave
