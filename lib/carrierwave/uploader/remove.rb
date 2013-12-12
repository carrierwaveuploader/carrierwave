# encoding: utf-8

module CarrierWave
  module Uploader
    module Remove
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      ##
      # Removes the file and reset it
      #
      def remove!
        with_callbacks(:remove) do
          delete_file
          @file = nil
          @cache_id = nil
        end
      end

      private 

      def delete_file
        begin 
          @file.delete if @file
        rescue Fog::Storage::Rackspace::NotFound
          # it does not exist
        end
      end


    end # Remove
  end # Uploader
end # CarrierWave
