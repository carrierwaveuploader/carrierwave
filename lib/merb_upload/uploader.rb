module Merb
  module Upload
    
    class Uploader
    
      class << self
      
        def upload!(identifier, file)
          self.new(identifier).upload(file)
        end
      
        def retrieve!(identifier)
          self.new(identifier)
        end
      
        def storage(storage = nil)
          @storage = storage if storage
          return @storage
        end
      
      end
    
      attr_accessor :identifier
    
      def initialize(identifier)
        @identifier = identifier
      end
    
      def filename
        identifier
      end
    
      def store_dir
        Merb::Plugins.config[:merb_upload][:store_dir]
      end
    
      def tmp_dir
        Merb::Plugins.config[:merb_upload][:tmp_dir]
      end
      
    end
    
  end
end