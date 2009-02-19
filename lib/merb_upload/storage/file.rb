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
          path = ::File.join(uploader.store_dir, uploader.filename)
          path = ::File.expand_path(path, uploader.root)
          file.move_to(path)
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
          path = ::File.join(uploader.store_dir, identifier)
          path = ::File.expand_path(path, uploader.root)
          Merb::Upload::SanitizedFile.new(path)
        end
        
      end
    end
    
  end
end