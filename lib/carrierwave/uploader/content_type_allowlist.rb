module CarrierWave
  module Uploader
    module ContentTypeAllowlist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_allowlist!
      end

      ##
      # Override this method in your uploader to provide an allowlist of files content types
      # which are allowed to be uploaded.
      # Not only strings but Regexp are allowed as well.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] an allowlist of content types which are allowed to be uploaded
      #
      # === Examples
      #
      #     def content_type_allowlist
      #       %w(text/json application/json)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def content_type_allowlist
      #       [/(text|application)\/json/]
      #     end
      #
      def content_type_allowlist
      end

    private

      def check_content_type_allowlist!(new_file)
        allowlist = content_type_allowlist
        if !allowlist && respond_to?(:content_type_whitelist) && content_type_whitelist
          ActiveSupport::Deprecation.warn "#content_type_whitelist is deprecated, use #content_type_allowlist instead." unless instance_variable_defined?(:@content_type_whitelist_warned)
          @content_type_whitelist_warned = true
          allowlist = content_type_whitelist
        end

        return unless allowlist

        content_type = new_file.content_type
        if !allowlisted_content_type?(allowlist, content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_allowlist_error", content_type: content_type,
                                                            allowed_types: Array(allowlist).join(", "), default: :"errors.messages.content_type_whitelist_error")
        end
      end

      def allowlisted_content_type?(allowlist, content_type)
        Array(allowlist).any? do |item|
          item = Regexp.quote(item) if item.class != Regexp
          content_type =~ /#{item}/
        end
      end

    end # ContentTypeAllowlist
  end # Uploader
end # CarrierWave
