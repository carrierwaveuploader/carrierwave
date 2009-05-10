module CarrierWave
  module Uploader
    module Remove

      ##
      # Removes the file and reset it
      #
      def remove!
        CarrierWave.logger.info 'CarrierWave: removing file'
        storage.destroy!(self, file)
        versions.each do |name, v|
          CarrierWave.logger.info "CarrierWave: removing file for version #{v.version_name}"
          v.remove!
        end
        @file = nil
        @cache_id = nil
      end

    end # Remove
  end # Uploader
end # CarrierWave