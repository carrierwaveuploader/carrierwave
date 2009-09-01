# encoding: utf-8

module CarrierWave
  module Uploader
    module DefaultPath

      def initialize(*args)
        super
        if default_path
          puts "WARNING: Default Path is deprecated and will be removed in CarrierWave 0.4. Please use default_url instead!"
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