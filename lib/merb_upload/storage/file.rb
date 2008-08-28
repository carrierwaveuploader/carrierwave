module Merb
  module Upload
    
    module Storage
      class File
        
        def initialize(uploader)
          @uploader = uploader
        end
        
        def upload!(file)
          destination = File.join(@uploader.store_dir, @uploader.filename)
          file.move_to(destination)
        end
        
        def retrieve!(file)
          source = File.join(@uploader.store_dir, @uploader.filename)
        end
        
      end
    end
    
  end
end