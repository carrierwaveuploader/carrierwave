module Merb
  module Upload
    
    module Storage
      class File < Abstract
        
        def initialize(uploader)
          @uploader = uploader
        end
        
        ##
        # Move the file to the uploader's store path.
        #
        # @param [Merb::Upload::Uploader] uploader an uploader object
        # @param [Merb::Upload::SanitizedFile] file the file to store
        #
        # @return [Merb::Upload::SanitizedFile] a sanitized file
        #
        def self.store!(uploader, file)
          file.move_to(::File.join(uploader.store_dir, uploader.filename))
          file
        end
        
        ##
        # Retrieve the file from its store path
        #
        # @param [Merb::Upload::Uploader] uploader an uploader object
        # @param [String] identifier the filename of the file
        #
        # @return [Merb::Upload::SanitizedFile] a sanitized file
        #
        def self.retrieve!(uploader, identifier)
          Merb::Upload::SanitizedFile.new(::File.join(uploader.store_dir, identifier))
        end
        
      end
    end
    
  end
end