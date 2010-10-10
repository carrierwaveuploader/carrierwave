# encoding: utf-8

module CarrierWave
  module Uploader
    module Rename
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        after :rename, :recreate_versions!
      end

      ##
      # Override this method in your uploader to check if the model has been updated.
      #
      # === Returns
      #
      # [NilClass, Boolean] true if the model has been changed, false otherwise
      #
      # === Examples
      #
      #     def stale_model?
      #       model.folder_changed? # because store_dir is based on the folder property of the model
      #     end
      #
      def stale_model?
         false
      end

      def rename?
        @rename || false
      end

      ##
      # Renames the file
      #
      def rename!
        return true if !self.rename?

        with_callbacks(:rename) do
          puts "[Rename][rename!] @file = #{@file.inspect} / #{@file.path} /#{model.inspect}"
          @file = storage.rename!(@original_file)
          @original_file = nil
          @rename = false
        end
      end

      private

      def check_stale_model!
        # the conditions below means: mountable uploader, already an existing file, model has been modified and not changing the file currently.
        @rename = self.file && self.model && self.stale_model? && @cache_id.nil?

        if self.rename?
          @original_file = self.file.clone
          @filename = self.model.send(:_mounter, self.mounted_as).identifier # default filename has to be the one from the model
        end
      end

    end # Rename
  end # Uploader
end # CarrierWave
