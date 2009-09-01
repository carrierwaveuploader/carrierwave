# encoding: utf-8

module CarrierWave
  module Uploader
    module Paths

      ##
      # === Returns
      #
      # [String] the directory where files will be publically accessible
      #
      def root
        CarrierWave.config[:root]
      end

    end # Paths
  end # Uploader
end # CarrierWave