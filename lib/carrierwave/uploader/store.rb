module CarrierWave
  module Uploader
    module Store

      module ClassMethods

        ##
        # Sets the storage engine to be used when storing files with this uploader.
        # Can be any class that implements a #store!(CarrierWave::SanitizedFile) and a #retrieve!
        # method. See lib/carrierwave/storage/file.rb for an example. Storage engines should
        # be added to CarrierWave.config[:storage_engines] so they can be referred
        # to by a symbol, which should be more convenient
        #
        # If no argument is given, it will simply return the currently used storage engine.
        #
        # === Parameters
        #
        # [storage (Symbol, Class)] The storage engine to use for this uploader
        #
        # === Returns
        #
        # [Class] the storage engine to be used with this uploader
        #
        # === Examples
        #
        #     storage :file
        #     storage CarrierWave::Storage::File
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
            @storage ||= get_storage_by_symbol(CarrierWave.config[:storage])
            @storage.setup!
          end
          return @storage
        end

        alias_method :storage=, :storage

      private

        def get_storage_by_symbol(symbol)
          eval(CarrierWave.config[:storage_engines][symbol])
        end

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
      # === Returns
      #
      # [String] a filename
      #
      def filename
        @filename
      end

      ##
      # Override this in your Uploader to change the directory where the file backend stores files.
      #
      # Other backends may or may not use this method, depending on their specific needs.
      #
      # === Returns
      #
      # [String] a directory
      #
      def store_dir
        CarrierWave.config[:store_dir]
      end

      ##
      # Calculates the path where the file should be stored. If +for_file+ is given, it will be
      # used as the filename, otherwise +CarrierWave::Uploader#filename+ is assumed.
      #
      # === Parameters
      #
      # [for_file (String)] name of the file <optional>
      #
      # === Returns
      #
      # [String] the store path
      #
      def store_path(for_file=filename)
        File.join(store_dir, [version_name, for_file].compact.join('_'))
      end

      ##
      # Stores the file by passing it to this Uploader's storage engine.
      #
      # If new_file is omitted, a previously cached file will be stored.
      #
      # === Parameters
      #
      # [new_file (File, IOString, Tempfile)] any kind of file object
      #
      def store!(new_file=nil)
        cache!(new_file) if new_file
        if @file and @cache_id
          @file = storage.store!(self, @file)
          @cache_id = nil
          versions.each { |name, v| v.store!(new_file) }
        end
      end

      ##
      # Retrieves the file from the storage.
      #
      # === Parameters
      #
      # [identifier (String)] uniquely identifies the file to retrieve
      #
      def retrieve_from_store!(identifier)
        @file = storage.retrieve!(self, identifier)
        versions.each { |name, v| v.retrieve_from_store!(identifier) }
      end

    private

      def storage
        self.class.storage
      end

    end # Store
  end # Uploader
end # CarrierWave