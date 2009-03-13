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
      # Move the file to the uploader's store path.
      #
      # @param [CarrierWave::Uploader] uploader an uploader object
      # @param [CarrierWave::SanitizedFile] file the file to store
      #
      # @return [CarrierWave::SanitizedFile] a sanitized file
      #
      def self.store!(uploader, file)
        path = ::File.join(uploader.store_dir, uploader.filename)
        path = ::File.expand_path(path, uploader.public)
        file.move_to(path)
        file
      end
      
      ##
      # Retrieve the file from its store path
      #
      # @param [CarrierWave::Uploader] uploader an uploader object
      # @param [String] identifier the filename of the file
      #
      # @return [CarrierWave::SanitizedFile] a sanitized file
      #
      def self.retrieve!(uploader, identifier)
        path = ::File.join(uploader.store_dir, identifier)
        path = ::File.expand_path(path, uploader.public)
        CarrierWave::SanitizedFile.new(path)
      end
      
    end # File
  end # Storage
end # CarrierWave