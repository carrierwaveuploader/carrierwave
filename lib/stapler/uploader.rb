module Stapler
  class Uploader
  
    class << self
    
      ##
      # Returns a list of processor callbacks which have been declared for this uploader
      #
      # @return [String] 
      #
      def processors
        @processors ||= []
      end
    
      ##
      # Adds a processor callback which applies operations as a file is uploaded.
      # The argument may be the name of any method of the uploader, expressed as a symbol,
      # or a list of such methods, or a hash where the key is a method and the value is
      # an array of arguments to call the method with
      #
      # @param [*Symbol, Hash{Symbol => Array[]}] args
      # @example
      #     class MyUploader < Stapler::Uploader
      #       process :sepiatone, :vignette
      #       process :scale => [200, 200]
      #     
      #       def sepiatone
      #         ...
      #       end
      #     
      #       def vignette
      #         ...
      #       end
      #     
      #       def scale(height, width)
      #         ...
      #       end
      #     end
      #
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
      
      ##
      # Sets the storage engine to be used when storing files with this uploader.
      # Can be any class that implements a #store!(Stapler::SanitizedFile) and a #retrieve!
      # method. See lib/stapler/storage/file.rb for an example. Storage engines should
      # be added to Stapler.config[:storage_engines] so they can be referred
      # to by a symbol, which should be more convenient
      #
      # If no argument is given, it will simply return the currently used storage engine.
      # 
      # @param [Symbol, Class] storage The storage engine to use for this uploader
      # @return [Class] the storage engine to be used with this uploader
      # @example
      #     storage :file
      #     storage Stapler::Storage::File
      #     storage MyCustomStorageEngine
      # 
      def storage(storage = nil)
        if storage.is_a?(Symbol)
          @storage = get_storage_by_symbol(storage)
          @storage.setup!
        elsif storage
          @storage = storage
          @storage.setup!
        elsif @storage.nil?
          # Get the storage from the superclass if there is one
          @storage = superclass.storage rescue nil
        end
        if @storage.nil?
          # If we were not able to find a store any other way, setup the default store
          @storage ||= get_storage_by_symbol(Stapler.config[:storage])
          @storage.setup!
        end
        return @storage
      end

      alias_method :storage=, :storage
      
      attr_accessor :version_name

      ##
      # Adds a new version to this uploader
      #
      # @param [#to_sym] name name of the version
      # @param [Proc] &block a block to eval on this version of the uploader
      #
      def version(name, &block)
        name = name.to_sym
        klass = Class.new(self)
        klass.version_name = name
        klass.class_eval(&block) if block
        versions[name] = klass
        class_eval <<-RUBY
          def #{name}
            versions[:#{name}]
          end
        RUBY
      end

      ##
      # @return [Hash{Symbol => Class}] a list of versions available for this uploader
      #
      def versions
        @versions ||= {}
      end

      ##
      # Generates a unique cache id for use in the caching system
      #
      # @return [String] a cache if in the format YYYYMMDD-HHMM-PID-RND
      #
      def generate_cache_id
        Time.now.strftime('%Y%m%d-%H%M') + '-' + Process.pid.to_s + '-' + ("%04d" % rand(9999))
      end
    
    private
    
      def get_storage_by_symbol(symbol)
        Stapler.config[:storage_engines][symbol]
      end
    
    end # class << self
  
    attr_reader :file, :model, :mounted_as
    
    ##
    # If a model is given as the first parameter, it will stored in the uploader, and
    # available throught +#model+. Likewise, mounted_as stores the name of the column
    # where this instance of the uploader is mounted. These values can then be used inside
    # your uploader.
    #
    # If you do not wish to mount your uploaders with the ORM extensions in -more then you
    # can override this method inside your uploader.
    #
    # @param [Object] model Any kind of model object
    # @param [Symbol] mounted_as The name of the column where this uploader is mounted
    # @example
    #     class MyUploader < Stapler::Uploader
    #       def store_dir
    #         File.join('public', 'files', mounted_as, model.permalink)
    #       end
    #     end
    #
    def initialize(model=nil, mounted_as=nil)
      @model = model
      @mounted_as = mounted_as
    end
    
    ##
    # Apply all process callbacks added through Staplerer.process
    #
    def process!
      self.class.processors.each do |method, args|
        self.send(method, *args)
      end
    end
    
    ##
    # @return [String] the path where the file is currently located.
    #
    def current_path
      file.path if file.respond_to?(:path)
    end
    
    ##
    # Returns a hash mapping the name of each version of the uploader to an instance of it
    #
    # @return [Hash{Symbol => Stapler::Uploader}] a list of uploader instances
    #
    def versions
      return @versions if @versions
      @versions = {}
      self.class.versions.each do |name, klass|
        @versions[name] = klass.new(model, mounted_as)
      end
      @versions
    end

    ##
    # @return [String] the location where this file is accessible via a url
    #
    def url
      if file.respond_to?(:url) and not file.url.blank?
        file.url
      elsif current_path
        File.expand_path(current_path).gsub(File.expand_path(Stapler.config[:public]), '')
      end
    end
    
    alias_method :to_s, :url
    
    ##
    # Returns a string that uniquely identifies the last stored file
    #
    # @return [String] uniquely identifies a file
    #
    def identifier
      file.identifier if file.respond_to?(:identifier)
    end
  
    ##
    # Override this in your Uploader to change the filename.
    #
    # Be careful using record ids as filenames. If the filename is stored in the database
    # the record id will be nil when the filename is set. Don't use record ids unless you
    # understand this limitation.
    #
    # Do not use the version_name in the filename, as it will prevent versions from being
    # loaded correctly.
    #
    # @return [String] a filename
    #
    def filename
      @filename
    end

    ##
    # @return [String] the name of this version of the uploader
    #
    def version_name
      self.class.version_name
    end
    
    ##
    # @return [String] the directory relative to which we will upload
    #
    def root
      Stapler.config[:root]
    end
  
    ####################
    ## Cache
    ####################
  
    ##
    # Override this in your Uploader to change the directory where files are cached.
    #
    # @return [String] a directory
    #
    def cache_dir
      Stapler.config[:cache_dir]
    end
    
    ##
    # Returns a String which uniquely identifies the currently cached file for later retrieval
    #
    # @return [String] a cache name, in the format YYYYMMDD-HHMM-PID-RND/filename.txt
    #
    def cache_name
      File.join(cache_id, [version_name, original_filename].compact.join('_')) if cache_id and original_filename
    end
    
    ##
    # Caches the given file unless a file has already been cached, stored or retrieved.
    #
    # @param [File, IOString, Tempfile] new_file any kind of file object
    # @raise [Stapler::FormNotMultipart] if the assigned parameter is a string
    #
    def cache(new_file)
      cache!(new_file) unless file
    end
    
    ##
    # Caches the given file. Calls process! to trigger any process callbacks.
    #
    # @param [File, IOString, Tempfile] new_file any kind of file object
    # @raise [Stapler::FormNotMultipart] if the assigned parameter is a string
    #
    def cache!(new_file)
      self.cache_id = Stapler::Uploader.generate_cache_id unless cache_id
      new_file = Stapler::SanitizedFile.new(new_file)
      raise Stapler::FormNotMultipart, "check that your upload form is multipart encoded" if new_file.string?

      @file = new_file

      @filename = new_file.filename
      self.original_filename = new_file.filename
      
      @file = @file.copy_to(cache_path)
      process!

      versions.each do |name, v|
        v.send(:cache_id=, cache_id)
        v.cache!(new_file)
      end
    end
    
    ##
    # Retrieves the file with the given cache_name from the cache, unless a file has
    # already been cached, stored or retrieved.
    #
    # @param [String] cache_name uniquely identifies a cache file
    #
    def retrieve_from_cache(cache_name)
      retrieve_from_cache!(cache_name) unless file
    rescue Stapler::InvalidParameter
    end
    
    ##
    # Retrieves the file with the given cache_name from the cache.
    #
    # @param [String] cache_name uniquely identifies a cache file
    # @raise [Stapler::InvalidParameter] if the cache_name is incorrectly formatted.
    #
    def retrieve_from_cache!(cache_name)
      self.cache_id, self.original_filename = cache_name.split('/', 2)
      @filename = original_filename
      @file = Stapler::SanitizedFile.new(cache_path)
      versions.each { |name, v| v.retrieve_from_cache!(cache_name) }
    end
    
    ####################
    ## STORE
    ####################
    
    ##
    # Override this in your Uploader to change the directory where the file backend stores files.
    #
    # Other backends may or may not use this method, depending on their specific needs.
    #
    # @return [String] a directory
    #
    def store_dir
      [Stapler.config[:store_dir], version_name].compact.join(File::Separator)
    end
    
    ##
    # Stores the file by passing it to this Uploader's storage engine, unless a file has
    # already been cached, stored or retrieved.
    #
    # If Stapler.config[:use_cache] is true, it will first cache the file
    # and apply any process callbacks before uploading it.
    #
    # @param [File, IOString, Tempfile] new_file any kind of file object
    #
    def store(new_file)
      store!(new_file) unless file
    end
    
    ##
    # Stores the file by passing it to this Uploader's storage engine.
    #
    # If new_file is omitted, a previously cached file will be stored.
    #
    # If Stapler.config[:use_cache] is true, it will first cache the file
    # and apply any process callbacks before uploading it.
    #
    # @param [File, IOString, Tempfile] new_file any kind of file object
    #
    def store!(new_file=nil)
      if Stapler.config[:use_cache]
        cache!(new_file) if new_file
        @file = storage.store!(self, @file)
        @cache_id = nil
      else
        new_file = Stapler::SanitizedFile.new(new_file)
        
        @filename = new_file.filename
        self.original_filename = filename
        
        @file = storage.store!(self, new_file)
      end
      versions.each { |name, v| v.store!(new_file) }
    end
    
    ##
    # Retrieves the file from the storage, unless a file has
    # already been cached, stored or retrieved.
    # 
    # @param [String] filename uniquely identifies the file to retrieve
    #
    def retrieve_from_store(filename)
      retrieve_from_store!(filename) unless file
    rescue Stapler::InvalidParameter
    end
    
    ##
    # Retrieves the file from the storage.
    # 
    # @param [String] identifier uniquely identifies the file to retrieve
    #
    def retrieve_from_store!(identifier)
      @file = storage.retrieve!(self, identifier)
      versions.each { |name, v| v.retrieve_from_store!(identifier) }
    end
    
  private
  
    def cache_path
      File.expand_path(File.join(cache_dir, cache_name), root)
    end
  
    def storage
      self.class.storage
    end
    
    attr_reader :cache_id, :original_filename

    def cache_id=(cache_id)
      raise Stapler::InvalidParameter, "invalid cache id" unless cache_id =~ /^[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}$/
      @cache_id = cache_id
    end
    
    def original_filename=(filename)
      raise Stapler::InvalidParameter, "invalid filename" unless filename =~ /^[a-z0-9\.\-\+_]+$/i
      @original_filename = filename
    end
    
  end # Uploader
end # Stapler