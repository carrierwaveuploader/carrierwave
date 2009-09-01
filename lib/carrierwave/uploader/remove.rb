# encoding: utf-8

module CarrierWave
  module Uploader
    module Remove

      depends_on CarrierWave::Uploader::Callbacks

      ##
      # Removes the file and reset it
      #
      def remove!
        with_callbacks(:remove) do
          @file.delete if @file
          @file = nil
          @cache_id = nil
        end
      end

    end # Remove
  end # Uploader
end # CarrierWave