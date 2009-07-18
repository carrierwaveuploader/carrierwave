# encoding: utf-8

module CarrierWave
  module Uploader
    module Paths

      ##
      # === Returns
      #
      # [String] the directory that is the root of the application
      #
      def root
        CarrierWave.config[:root]
      end

      ##
      # === Returns
      #
      # [String] the directory where files will be publically accessible
      #
      def public
        CarrierWave.config[:public]
      end

    end # Paths
  end # Uploader
end # CarrierWave