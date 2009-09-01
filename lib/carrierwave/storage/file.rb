# encoding: utf-8

module CarrierWave
  module Storage

    ##
    # File storage stores file to the Filesystem (surprising, no?). There's really not much
    # to it, it uses the store_dir defined on the uploader as the storage location. That's
    # pretty much it.
    #
    class File < Abstract

      ##
      # Move the file to the uploader's store path.
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def store!(file)
        path = ::File.join(uploader.store_path)
        path = ::File.expand_path(path, uploader.root)
        file.move_to(path, CarrierWave.config[:permissions])
        file
      end

      ##
      # Retrieve the file from its store path
      #
      # === Parameters
      #
      # [identifier (String)] the filename of the file
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def retrieve!(identifier)
        path = ::File.join(uploader.store_path(identifier))
        path = ::File.expand_path(path, uploader.root)
        CarrierWave::SanitizedFile.new(path)
      end

    end # File
  end # Storage
end # CarrierWave
