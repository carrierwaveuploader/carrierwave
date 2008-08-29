module Merb
  module Upload
    
    class Uploader
    
      class << self
      
        def store!(identifier, file)
          self.new(identifier).store!(file)
        end
      
        def retrieve_from_cache!(identifier)
          uploader = self.new(identifier)
          uploader.retrieve_from_cache!
          uploader
        end
        
        def retrieve_from_store!(identifier)
          uploader = self.new(identifier)
          uploader.retrieve_from_store!
          uploader
        end
      
        def storage(storage = nil)
          if storage.is_a?(Symbol)
            @storage = Merb::Plugins.config[:merb_upload][:storage_engines][storage]
          elsif storage
            @storage = storage
          end
          return @storage
        end
      
      end
    
      attr_accessor :identifier
      
      attr_reader :file
    
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
      
      def store_path
        store_dir / filename
      end
      
      def tmp_path
        tmp_dir / filename
      end
      
      def cache!(new_file)
        new_file = Merb::Upload::SanitizedFile.new(new_file)
        raise Merb::Upload::FormNotMultipart, "check that your upload form is multipart encoded" if new_file.string?
        @file = new_file
        @file.move_to(tmp_path)
      end
      
      def retrieve_from_cache!
        @file = Merb::Upload::SanitizedFile.new(tmp_path)
      end
      
      def store!(new_file=nil)
        cache!(new_file) if new_file
        @file = storage.store!(@file)
      end
      
      def retrieve_from_store!
        @file = storage.retrieve!
      end
      
      def storage
        @storage ||= self.class.storage.new(self)
      end
      
    end
    
  end
end