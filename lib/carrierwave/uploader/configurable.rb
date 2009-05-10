module CarrierWave
  module Uploader
    module Configurable

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

      def default_path; end

    end # Configurable
  end # Uploader
end # CarrierWave