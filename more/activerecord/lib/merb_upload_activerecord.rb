module Merb
  module Upload
    module ActiveRecord
      
      def uploaders
        @uploaders ||= {}
      end
      
      def mount_uploader(column, uploader)
        
        uploaders[column] = uploader
        
        class_eval <<-EOF, __FILE__, __LINE__
        
          after_save :store_#{column}!
        
          def store_#{column}!
            @#{column}_uploader.store! if @#{column}_uploader
          end
        
          def #{column}
            @#{column}_uploader
          end
          
          def #{column}=(new_file)
            @#{column}_uploader ||= self.class.uploaders[:#{column}].new(self, :#{column})
            @#{column}_uploader.cache!(new_file)
          end
        EOF
      end
      
    end # ActiveRecord
  end # Upload
end # Merb

ActiveRecord::Base.send(:extend, Merb::Upload::ActiveRecord)