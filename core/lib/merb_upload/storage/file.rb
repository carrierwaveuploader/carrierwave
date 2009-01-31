module Merb
  module Upload
    
    module Storage
      class File
        
        def initialize(uploader)
          @uploader = uploader
        end
        
        def store!(file)
          file.move_to(@uploader.store_path)
          file
        end
        
        def retrieve!
          Merb::Upload::SanitizedFile.new(@uploader.store_path)
        end
        
      end
    end
    
  end
end