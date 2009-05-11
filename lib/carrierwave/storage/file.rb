module CarrierWave
  module Storage

    ##
    # File storage stores file to the Filesystem (surprising, no?). There's really not much
    # to it, it uses the store_dir defined on the uploader as the storage location. That's
    # pretty much it.
    #
    class File < Abstract
      
      def initialize(uploader)
        @uploader = uploader
      end
      
      ##
      # Delete the file to the uploader's store path.
      #
      # === Parameters
      #
      # [uploader (CarrierWave::Uploader)] an uploader object
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [bool] True if file was removed or false
      #
      def self.destroy!(uploader, file)
        unless file.blank?
          CarrierWave.logger.info "CarrierWave::Storage::File: removing file #{file.path}"
          file.delete
        end
      end

      ##
      # Move the file to the uploader's store path.
      #
      # === Parameters
      #
      # [uploader (CarrierWave::Uploader)] an uploader object
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def self.store!(uploader, file)
        path = ::File.join(uploader.store_path)
        path = ::File.expand_path(path, uploader.public)
        file.move_to(path, CarrierWave.config[:permissions])
        file
      end
      
      ##
      # Retrieve the file from its store path
      #
      # === Parameters
      #
      # [uploader (CarrierWave::Uploader)] an uploader object
      # [identifier (String)] the filename of the file
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def self.retrieve!(uploader, identifier)
        path = ::File.join(uploader.store_path(identifier))
        path = ::File.expand_path(path, uploader.public)
        CarrierWave::SanitizedFile.new(path)
      end
      
    end # File
  end # Storage
end # CarrierWave
