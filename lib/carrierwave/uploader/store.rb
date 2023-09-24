module CarrierWave
  module Uploader
    module Store
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Cache

      included do
        prepend Module.new {
          def initialize(*)
            super
            @file, @filename, @cache_id, @identifier, @deduplication_index = nil
          end
        }
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
      # Returns a filename which doesn't conflict with already-stored files.
      #
      # === Returns
      #
      # [String] the filename with suffix added for deduplication
      #
      def deduplicated_filename
        return unless filename
        return filename unless @deduplication_index

        parts = filename.split('.')
        basename = parts.shift
        basename.sub!(/ ?\(\d+\)\z/, '')
        ([basename.to_s + (@deduplication_index > 1 ? "(#{@deduplication_index})" : '')] + parts).join('.')
      end

      ##
      # Calculates the path where the file should be stored. If +for_file+ is given, it will be
      # used as the identifier, otherwise +CarrierWave::Uploader#identifier+ is assumed.
      #
      # === Parameters
      #
      # [for_file (String)] name of the file <optional>
      #
      # === Returns
      #
      # [String] the store path
      #
      def store_path(for_file=identifier)
        File.join([store_dir, full_filename(for_file)].compact)
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
        cache!(new_file) if new_file && !cached?
        if !cache_only && @file && @cache_id
          with_callbacks(:store, new_file) do
            new_file = storage.store!(@file)
            if delete_tmp_file_after_storage
              @file.delete unless move_to_store
              cache_storage.delete_dir!(cache_path(nil))
            end
            @file = new_file
            @identifier = storage.identifier
            @original_filename = @cache_id = @deduplication_index = nil
            @staged = false
          end
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
        with_callbacks(:retrieve_from_store, identifier) do
          @file = storage.retrieve!(identifier)
          @identifier = identifier
        end
      end

      ##
      # Look for an identifier which doesn't collide with the given already-stored identifiers.
      # It is done by adding a index number as the suffix.
      # For example, if there's 'image.jpg' and the @deduplication_index is set to 2,
      # The stored file will be named as 'image(2).jpg'.
      #
      # === Parameters
      #
      # [current_identifiers (Array[String])] List of identifiers for already-stored files
      #
      def deduplicate(current_identifiers)
        @deduplication_index = nil
        return unless current_identifiers.include?(identifier)

        (1..current_identifiers.size + 1).each do |i|
          @deduplication_index = i
          break unless current_identifiers.include?(identifier)
        end
      end

    private

      def full_filename(for_file)
        forcing_extension(for_file)
      end

      def storage
        @storage ||= self.class.storage.new(self)
      end

    end # Store
  end # Uploader
end # CarrierWave
