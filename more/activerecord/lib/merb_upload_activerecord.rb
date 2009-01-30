module Merb
  
  module Upload
    
    module ActiveRecord
      
      def attach_uploader(uploader)
        class_eval do
          def file
            
          end
        end
      end
      
      def mount_uploader(column, uploader)
      end
      
    end
    
  end
  
end

ActiveRecord::Base.send(:extend, Merb::Upload::ActiveRecord)