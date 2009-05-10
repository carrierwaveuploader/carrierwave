module CarrierWave
  module Uploader
    module DefaultPath

      def initialize(*args)
        super
        if default_path
          @file = CarrierWave::SanitizedFile.new(File.expand_path(default_path, public))
          def @file.blank?; true; end
        end
      end

      ##
      # Override this method in your uploader to provide a default path
      # in case no file has been cached/stored yet.
      #
      def default_path; end

    end # DefaultPath
  end # Uploader
end # CarrierWave