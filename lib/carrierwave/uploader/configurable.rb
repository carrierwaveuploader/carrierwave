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

      def default_path; end

    end # Configurable
  end # Uploader
end # CarrierWave