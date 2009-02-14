require 'activerecord'

module Merb
  module Upload
    module ActiveRecord
      
      include Merb::Upload::Mount
      
      module Extension
      
        def read_uploader(column)
          self[column]
        end
      
        def write_uploader(column, identifier)
          self[column] = identifier
        end
      
      end
      
      def after_mount(column, uploader)
        
        include Merb::Upload::ActiveRecord::Extension
        
        before_save do |record|
          record.store_uploader(column)
        end
      end
      
    end # ActiveRecord
  end # Upload
end # Merb

ActiveRecord::Base.send(:extend, Merb::Upload::ActiveRecord)