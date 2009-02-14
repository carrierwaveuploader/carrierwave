module Merb
  module Upload

    module Mount
      
      module Extension
        
        def uploaders
          @uploaders ||= {}
        end
        
        def uploader(column)
          uploaders[column] ||= self.class.uploaders[column].new(self, column)
        end
        
        def store_uploader(column)
          uploaders[column].store! if uploaders[column]
        end
        
        def get_uploader(column)
          return uploaders[column] if uploaders[column]

          identifier = read_uploader(column)
          
          unless identifier.blank?
            uploader(column).retrieve_from_store!(identifier)
            uploader(column)
          end
        end
        
        def set_uploader(column, new_file)
          new_file = Merb::Upload::SanitizedFile.new(new_file)
          
          unless new_file.empty?
            uploader(column).cache!(new_file) 
            write_uploader(column, uploader(column).identifier)
          end
        end
        
      end
      
      def uploaders
        @uploaders ||= {}
      end
      
      def mount_uploader(column, uploader)
        
        uploaders[column.to_sym] = uploader
        
        include Merb::Upload::Mount::Extension
        
        class_eval <<-EOF, __FILE__, __LINE__+1
          def #{column}
            get_uploader(:#{column})
          end

          def #{column}=(new_file)
            set_uploader(:#{column}, new_file)
          end                                                                         
        EOF
        
        after_mount(column, uploader) if respond_to?(:after_mount)
      end
      
    end

  end
end