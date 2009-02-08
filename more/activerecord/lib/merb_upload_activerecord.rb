require 'activerecord'

module Merb
  module Upload
    module ActiveRecord
      
      def uploaders
        @uploaders ||= {}
      end
      
      def mount_uploader(column, uploader)
        
        uploaders[column.to_sym] = uploader
        
        class_eval <<-EOF, __FILE__, __LINE__
        
          after_save :store_#{column}!                                                        # after_save :store_image!
                                                                                              # 
          before_validation :set_#{column}_filename                                           # before_validation :set_image_filename
                                                                                              # 
          def store_#{column}!                                                                # def store_image!
            @#{column}_uploader.store! if @#{column}_uploader                                 #   @image_uploader.store! if @image_uploader
          end                                                                                 # end
                                                                                              # 
          def #{column}                                                                       # def image
            return @#{column}_uploader if @#{column}_uploader                                 #   return @image_uploader if @image_uploader
            unless self[:#{column}].blank?                                                    #   unless self[:image].blank?
              @#{column}_uploader ||= self.class.uploaders[:#{column}].new(self, :#{column})  #     @image_uploader ||= self.class.uploaders[:image].new(self, :image)
              @#{column}_uploader.retrieve_from_store!(self[:#{column}])                      #     @image_uploader.retrieve_from_store!(self[:image])
              @#{column}_uploader                                                             #     @image_uploader
            end                                                                               #   end
          end                                                                                 # end
                                                                                              # 
          def #{column}=(new_file)                                                            # def image=(new_file)
            new_file = Merb::Upload::SanitizedFile.new(new_file)                              #   new_file = Merb::Upload::SanitizedFile.new(new_file)
            unless new_file.empty?                                                            #   unless new_file.empty?
              @#{column}_uploader ||= self.class.uploaders[:#{column}].new(self, :#{column})  #     @image_uploader ||= self.class.uploaders[:image].new(self, :image)
              @#{column}_uploader.cache!(new_file)                                            #     @image_uploader.cache!(new_file)
            end                                                                               #   end
          end                                                                                 # end
                                                                                              # 
          private                                                                             # private
                                                                                              # 
          def set_#{column}_filename                                                          # def set_image_filename
            self[:#{column}] = @#{column}_uploader.filename if @#{column}_uploader            #   self[:image] = @image_uploader.filename if @image_uploader
          end                                                                                 # end
        EOF
      end
      
    end # ActiveRecord
  end # Upload
end # Merb

ActiveRecord::Base.send(:extend, Merb::Upload::ActiveRecord)