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
      
      def current_path
        file.path if file
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
        store_dir / filename
      end
      
      def cache_path
        cache_dir / cache_id / filename
      end
      
      def cache_name
        cache_id / identifier if cache_id and identifier
      end
      
      def cache(new_file)
        cache!(new_file) unless file
      end
      
      def cache!(new_file)
        @cache_id = generate_cache_id
        
        new_file = Merb::Upload::SanitizedFile.new(new_file)
        raise Merb::Upload::FormNotMultipart, "check that your upload form is multipart encoded" if new_file.string?

        @identifier = new_file.filename

        @file = new_file
        @file.move_to(cache_path)
        process!
        
        return @cache_id
      end
      
      def retrieve_from_cache(cache_id)
        retrieve_from_cache!(cache_id) unless file
      rescue Merb::Upload::InvalidParameter
      end
      
      def retrieve_from_cache!(cache_name)
        self.cache_id, self.identifier = cache_name.split('/', 2)
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
          new_file = Merb::Upload::SanitizedFile.new(new_file)
          @identifier = new_file.filename
          @file = storage.store!(new_file)
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
    
      def cache_id=(cache_id)
        raise Merb::Upload::InvalidParameter, "invalid cache id" unless valid_cache_id?(cache_id)
        @cache_id = cache_id
      end
      
      def identifier=(identifier)
        raise Merb::Upload::InvalidParameter, "invalid identifier" unless identifier =~ /^[a-z0-9\.\-\+_]+$/i
        @identifier = identifier
      end
      
      def generate_cache_id
        Time.now.strftime('%Y%m%d-%H%M') + '-' + Process.pid.to_s + '-' + ("%04d" % rand(9999))
      end
      
      def valid_cache_id?(cache_id)
        /^[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}$/ =~ cache_id
      end
      
    end
    
  end
end