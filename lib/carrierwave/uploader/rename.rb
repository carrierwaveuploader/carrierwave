# encoding: utf-8

module CarrierWave
  module Uploader
    module Rename
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        after :rename!, :recreate_versions!
      end

      attr_reader :new_identifier

      ##
      # Override this method in your uploader to check if the store_dir or the filename has been updated.
      #
      # === Returns
      #
      # [NilClass, Boolean] true if the model has been changed, false otherwise
      #
      # === Examples
      #
      #     def stale_model?
      #       model.folder_changed? # because store_dir uses model_changes
      #     end
      #
      def stale_model?
        false
      end

      def filename_from_model
        self.model.send(:_mounter, self.mounted_as).identifier
      end

      ##
      # Renames the file
      #
      def rename!
        return true if !@stale_model || @cache_id

        with_callbacks(:rename) do
          # puts "[Rename][rename!] @file = #{@file.inspect}"
          @file = storage.rename!(@file)
          @old_file = nil
        end
      end

      private

      def check_stale_model!
        @stale_model = self.stale_model?
        @new_identifier = self.filename_from_model
      end

    end # Remove
  end # Uploader
end # CarrierWave
