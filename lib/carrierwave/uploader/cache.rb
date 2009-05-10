module CarrierWave
  module Uploader
    module Cache

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
        File.join(cache_id, [version_name, original_filename].compact.join('_')) if cache_id and original_filename
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
          if extension_white_list and not extension_white_list.include?(new_file.extension.to_s)
            raise CarrierWave::IntegrityError, "You are not allowed to upload #{new_file.extension.inspect} files, allowed types: #{extension_white_list.inspect}"
          end

          self.cache_id = CarrierWave::Uploader.generate_cache_id unless cache_id

          @file = new_file

          @filename = new_file.filename
          self.original_filename = new_file.filename

          if CarrierWave.config[:cache_to_cache_dir]
            @file = @file.copy_to(cache_path, CarrierWave.config[:permissions])
          end

          process!

          versions.each do |name, v|
            v.send(:cache_id=, cache_id)
            v.cache!(new_file)
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
        self.cache_id, self.original_filename = cache_name.to_s.split('/', 2)
        @filename = original_filename
        @file = CarrierWave::SanitizedFile.new(cache_path)
        versions.each { |name, v| v.retrieve_from_cache!(cache_name) }
      end

    private

      def cache_path
        File.expand_path(File.join(cache_dir, cache_name), public)
      end

      attr_reader :cache_id, :original_filename

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