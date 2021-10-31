module CarrierWave
  module Uploader
    module ExtensionDenylist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_extension_denylist!
      end

      ##
      # Override this method in your uploader to provide a denylist of extensions which
      # are prohibited to be uploaded. Compares the file's extension case insensitive.
      # Furthermore, not only strings but Regexp are allowed as well.
      #
      # When using a Regexp in the denylist, `\A` and `\z` are automatically added to
      # the Regexp expression, also case insensitive.
      #
      # === Returns

      # [NilClass, String, Regexp, Array[String, Regexp]] a deny list of extensions which are prohibited to be uploaded
      #
      # === Examples
      #
      #     def extension_denylist
      #       %w(swf tiff)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def extension_denylist
      #       [/swf/, 'tiff']
      #     end
      #
      def extension_denylist
      end

    private

      def check_extension_denylist!(new_file)
        denylist = extension_denylist
        if !denylist && respond_to?(:extension_blacklist) && extension_blacklist
          ActiveSupport::Deprecation.warn "#extension_blacklist is deprecated, use #extension_denylist instead." unless instance_variable_defined?(:@extension_blacklist_warned)
          @extension_blacklist_warned = true
          denylist = extension_blacklist
        end

        return unless denylist

        ActiveSupport::Deprecation.warn "Use of #extension_denylist is deprecated for the security reason, use #extension_allowlist instead to explicitly state what are safe to accept" unless instance_variable_defined?(:@extension_denylist_warned)
        @extension_denylist_warned = true

        extension = new_file.extension.to_s
        if denylisted_extension?(denylist, extension)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.extension_denylist_error", extension: new_file.extension.inspect,
                                                            prohibited_types: Array(extension_denylist).join(", "), default: :"errors.messages.extension_blacklist_error")
        end
      end

      def denylisted_extension?(denylist, extension)
        Array(denylist).any? { |item| extension =~ /\A#{item}\z/i }
      end
    end
  end
end
