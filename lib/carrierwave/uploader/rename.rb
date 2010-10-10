# encoding: utf-8

module CarrierWave
  module Uploader
    module Rename
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        after :rename!, :recreate_versions!
      end

      # attr_reader :new_identifier

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
          @rename = false
        end
      end

      private

      def check_stale_model!
        @rename = self.stale_model? && @cache_id.nil?

        if self.rename? && self.model
          # @new_identifier = self.model.send(:_mounter, self.mounted_as).identifier
          @filename = self.model.send(:_mounter, self.mounted_as).identifier
        end
      end

    end # Rename
  end # Uploader
end # CarrierWave
