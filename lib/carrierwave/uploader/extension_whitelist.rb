# encoding: utf-8

module CarrierWave
  module Uploader
    module ExtensionWhitelist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_whitelist!
      end

      ##
      # Override this method in your uploader to provide a white list of extensions which
      # are allowed to be uploaded.
      #
      # === Returns
      #
      # [NilClass, Array[String]] a white list of extensions which are allowed to be uploaded
      #
      # === Examples
      #
      #     def extension_white_list
      #       %w(jpg jpeg gif png)
      #     end
      #
      def extension_white_list; end

    private

      def check_whitelist!(new_file)
        if extension_white_list and not extension_white_list.include?(new_file.extension.to_s)
          raise CarrierWave::IntegrityError, "You are not allowed to upload #{new_file.extension.inspect} files, allowed types: #{extension_white_list.inspect}"
        end
      end

    end # ExtensionWhitelist
  end # Uploader
end # CarrierWave
