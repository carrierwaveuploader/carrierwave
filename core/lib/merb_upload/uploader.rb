module Merb
  module Upload
    
    class Uploader
    
      class << self
      
        def processors
          @processors ||= []
        end
      
        def process(*args)
          args.each do |arg|
            if arg.is_a?(Hash)
              arg.each do |method, args|
                processors.push([method, args])
              end
            else
              processors.push([arg, []])
            end
          end
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
      
      attr_reader :file, :cache_id
      
      def process!
        self.class.processors.each do |method, args|
          self.send(method, *args)
        end
      end
    
      def initialize(identifier)
        @identifier = identifier
      end
      
      def current_path
        file ? file.path : store_path
      end
    
      def filename
        identifier
      end
    
      def store_dir
        Merb::Plugins.config[:merb_upload][:store_dir]
      end
    
      def cache_dir
        Merb::Plugins.config[:merb_upload][:cache_dir]
      end
      
      def store_path
        store_dir / cache_id / filename
      end
      
      def cache_path
        cache_dir / cache_id / filename
      end
      
      def cache(new_file)
        cache!(new_file) unless file
      end
      
      def cache!(new_file)
        @cache_id = generate_cache_id
        
        new_file = Merb::Upload::SanitizedFile.new(new_file)
        raise Merb::Upload::FormNotMultipart, "check that your upload form is multipart encoded" if new_file.string?
        @file = new_file
        @file.move_to(cache_path)
        process!
        
        return @cache_id
      end
      
      def retrieve_from_cache(cache_id)
        retrieve_from_cache!(cache_id) unless file
      end
      
      def retrieve_from_cache!(cache_id)
        @cache_id = cache_id
        @file = Merb::Upload::SanitizedFile.new(cache_path)
      end
      
      def store(new_file=nil)
        store!(new_file) unless file
      end
      
      def store!(new_file=nil)
        if Merb::Plugins.config[:merb_upload][:use_cache]
          cache!(new_file) if new_file
          @file = storage.store!(@file)
        else
          @file = storage.store!(Merb::Upload::SanitizedFile.new(new_file))
        end
      end
      
      def retrieve_from_store
        retrieve_from_store! unless file
      end
      
      def retrieve_from_store!
        @file = storage.retrieve!
      end
      
      def storage
        @storage ||= self.class.storage.new(self)
      end
      
    private
      
      def generate_cache_id
        Time.now.strftime('%Y%m%d-%H%M') + '-' + Process.pid.to_s + '-' + ("%04d" % rand(9999))
      end
      
    end
    
  end
end