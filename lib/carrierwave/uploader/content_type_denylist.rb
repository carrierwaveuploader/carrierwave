module CarrierWave
  module Uploader
    module ContentTypeDenylist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_denylist!
      end

      ##
      # Override this method in your uploader to provide a denylist of files content types
      # which are not allowed to be uploaded.
      # Not only strings but Regexp are allowed as well.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] a denylist of content types which are not allowed to be uploaded
      #
      # === Examples
      #
      #     def content_type_denylist
      #       %w(text/json application/json)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def content_type_denylist
      #       [/(text|application)\/json/]
      #     end
      #
      def content_type_denylist
      end

    private

      def check_content_type_denylist!(new_file)
        denylist = content_type_denylist
        if !denylist && respond_to?(:content_type_blacklist) && content_type_blacklist
          ActiveSupport::Deprecation.warn "#content_type_blacklist is deprecated, use #content_type_denylist instead." unless instance_variable_defined?(:@content_type_blacklist_warned)
          @content_type_blacklist_warned = true
          denylist = content_type_blacklist
        end

        return unless denylist

        ActiveSupport::Deprecation.warn "Use of #content_type_denylist is deprecated for the security reason, use #content_type_allowlist instead to explicitly state what are safe to accept" unless instance_variable_defined?(:@content_type_denylist_warned)
        @content_type_denylist_warned = true

        content_type = new_file.content_type
        if denylisted_content_type?(denylist, content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_denylist_error",
                                                            content_type: content_type, default: :"errors.messages.content_type_blacklist_error")
        end
      end

      def denylisted_content_type?(denylist, content_type)
        Array(denylist).any? { |item| content_type =~ /#{item}/ }
      end

    end # ContentTypeDenylist
  end # Uploader
end # CarrierWave
