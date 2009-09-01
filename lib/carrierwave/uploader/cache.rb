# encoding: utf-8

module CarrierWave
  module Uploader
    module Cache

      depends_on CarrierWave::Uploader::Paths
      depends_on CarrierWave::Uploader::Callbacks

      ##
      # Returns true if the uploader has been cached
      #
      # === Returns
      #
      # [Bool] whether the current file is cached
      #
      def cached?
        @cache_id
      end

      ##
      # Override this in your Uploader to change the directory where files are cached.
      #
      # === Returns
      #
      # [String] a directory
      #
      def cache_dir
        CarrierWave.config[:cache_dir]
      end

      ##
      # Returns a String which uniquely identifies the currently cached file for later retrieval
      #
      # === Returns
      #
      # [String] a cache name, in the format YYYYMMDD-HHMM-PID-RND/filename.txt
      #
      def cache_name
        File.join(cache_id, full_original_filename) if cache_id and original_filename
      end

      ##
      # Caches the given file. Calls process! to trigger any process callbacks.
      #
      # === Parameters
      #
      # [new_file (File, IOString, Tempfile)] any kind of file object
      #
      # === Raises
      #
      # [CarrierWave::FormNotMultipart] if the assigned parameter is a string
      #
      def cache!(new_file)
        new_file = CarrierWave::SanitizedFile.new(new_file)
        raise CarrierWave::FormNotMultipart if new_file.is_path?

        unless new_file.empty?
          with_callbacks(:cache, new_file) do
            self.cache_id = CarrierWave.generate_cache_id unless cache_id

            @filename = new_file.filename
            self.original_filename = new_file.filename

            @file = new_file.copy_to(cache_path, CarrierWave.config[:permissions])
          end
        end
      end

      ##
      # Retrieves the file with the given cache_name from the cache.
      #
      # === Parameters
      #
      # [cache_name (String)] uniquely identifies a cache file
      #
      # === Raises
      #
      # [CarrierWave::InvalidParameter] if the cache_name is incorrectly formatted.
      #
      def retrieve_from_cache!(cache_name)
        with_callbacks(:retrieve_from_cache, cache_name) do
          self.cache_id, self.original_filename = cache_name.to_s.split('/', 2)
          @filename = original_filename
          @file = CarrierWave::SanitizedFile.new(cache_path)
        end
      end

    private

      def cache_path
        File.expand_path(File.join(cache_dir, cache_name), public)
      end

      attr_reader :cache_id, :original_filename

      # We can override the full_original_filename method in other modules
      alias_method :full_original_filename, :original_filename

      def cache_id=(cache_id)
        raise CarrierWave::InvalidParameter, "invalid cache id" unless cache_id =~ /\A[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}\z/
        @cache_id = cache_id
      end

      def original_filename=(filename)
        raise CarrierWave::InvalidParameter, "invalid filename" unless filename =~ /\A[a-z0-9\.\-\+_]+\z/i
        @original_filename = filename
      end

    end # Cache
  end # Uploader
end # CarrierWave