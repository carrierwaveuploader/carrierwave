module Merb
  module Upload
    
    module Storage
      class File
        
        def initialize(uploader)
          @uploader = uploader
        end
        
        ##
        # Move the file to the uploader's store path.
        #
        # @param [File, IOString, Tempfile] file any kind of file object
        def store!(file)
          file.move_to(@uploader.store_dir / @uploader.filename)
          file
        end
        
        ##
        # Retrieve the file from its store path
        def retrieve!(identifier)
          Merb::Upload::SanitizedFile.new(@uploader.store_dir / identifier)
        end
        
      end
    end
    
  end
end