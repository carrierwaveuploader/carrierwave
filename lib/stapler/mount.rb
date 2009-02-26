module Stapler

    module Mount
      
      module Extension
        
      private

        def uploaders
          @uploaders ||= {}
        end
        
        def store_uploader!(column)
          if uploaders[column]
            uploaders[column].store!
            write_uploader(column, uploaders[column].identifier)
          end
        end
        
        def get_uploader(column)
          return uploaders[column] if uploaders[column]

          identifier = read_uploader(column)
          
          unless identifier.blank?
            uploaders[column] ||= self.class.uploaders[column].new(self, column)
            uploaders[column].retrieve_from_store!(identifier)
            uploaders[column]
          end
        end
        
        def set_uploader(column, new_file)
          new_file = Stapler::SanitizedFile.new(new_file)
          
          unless new_file.empty?
            uploaders[column] ||= self.class.uploaders[column].new(self, column)
            uploaders[column].cache!(new_file) 
          end
        end
        
        def get_uploader_cache(column)
          uploaders[column].cache_name if uploaders[column]
        end

        def set_uploader_cache(column, cache_name)
          unless cache_name.blank?
            uploaders[column] ||= self.class.uploaders[column].new(self, column)
            uploaders[column].retrieve_from_cache(cache_name)
          end
        end

      end
      
      def uploaders
        @uploaders ||= {}
      end
      
      def mount_uploader(column, uploader=nil, &block)
        unless uploader
          uploader = Class.new(Stapler::Uploader)
          uploader.class_eval(&block)
        end
        
        uploaders[column.to_sym] = uploader
        
        include Stapler::Mount::Extension
        
        class_eval <<-EOF, __FILE__, __LINE__+1
          def #{column}                                     # def image
            get_uploader(:#{column})                        #   get_uploader(:image)
          end                                               # end
                                                            #
          def #{column}=(new_file)                          # def image=(new_file)
            set_uploader(:#{column}, new_file)              #   set_uploader(:image, new_file)
          end                                               # end
                                                            #
          def #{column}_cache                               # def image_cache
            get_uploader_cache(:#{column})                  #   get_uploader_cache(:image)
          end                                               # end
                                                            #
          def #{column}_cache=(cache_name)                  # def image_cache=(cache_name)
            set_uploader_cache(:#{column}, cache_name)      #   set_uploader_cache(:image, cache_name)
          end                                               # end
                                                            #
          def store_#{column}!                              # def store_image!
            store_uploader!(:#{column})                     #   store_uploader!(:image)
          end                                               # end
        EOF
        
        after_mount(column, uploader) if respond_to?(:after_mount)
      end
      
    end

end