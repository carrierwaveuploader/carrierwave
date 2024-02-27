module CarrierWave

  # this is an internal class, used by CarrierWave::Mount so that
  # we don't pollute the model with a lot of methods.
  class Mounter # :nodoc:
    class Single < Mounter # :nodoc
      def identifier
        uploaders.first&.identifier
      end

      def temporary_identifier
        temporary_identifiers.first
      end
    end

    class Multiple < Mounter # :nodoc
      def identifier
        uploaders.map(&:identifier).presence
      end

      def temporary_identifier
        temporary_identifiers.presence
      end
    end

    def self.build(record, column)
      if record.class.uploader_options[column][:multiple]
        Multiple.new(record, column)
      else
        Single.new(record, column)
      end
    end

    attr_reader :column, :record, :remote_urls, :remove,
                :integrity_errors, :processing_errors, :download_errors
    attr_accessor :remote_request_headers, :uploader_options

    def initialize(record, column)
      @record = record
      @column = column
      @options = record.class.uploader_options[column]
      @download_errors = []
      @processing_errors = []
      @integrity_errors = []

      @removed_uploaders = []
      @added_uploaders = []
    end

    def uploader_class
      record.class.uploaders[column]
    end

    def blank_uploader
      uploader_class.new(record, column)
    end

    def identifiers
      uploaders.map(&:identifier)
    end

    def read_identifiers
      [record.read_uploader(serialization_column)].flatten.reject(&:blank?)
    end

    def uploaders
      @uploaders ||= read_identifiers.map do |identifier|
        uploader = blank_uploader
        uploader.retrieve_from_store!(identifier)
        uploader
      end
    end

    def cache(new_files)
      return if !new_files.is_a?(Array) && new_files.blank?
      old_uploaders = uploaders
      @uploaders = new_files.map do |new_file|
        handle_error do
          if new_file.is_a?(String)
            if (uploader = old_uploaders.detect { |old_uploader| old_uploader.identifier == new_file })
              uploader.staged = true
              uploader
            else
              begin
                uploader = blank_uploader
                uploader.retrieve_from_cache!(new_file)
                uploader
              rescue CarrierWave::InvalidParameter
                nil
              end
            end
          else
            uploader = blank_uploader
            uploader.cache!(new_file)
            uploader
          end
        end
      end.reject(&:blank?)
      @removed_uploaders += (old_uploaders - @uploaders)
      write_temporary_identifier
    end

    def cache_names
      uploaders.map(&:cache_name).compact
    end

    def cache_names=(cache_names)
      cache_names = cache_names.reject(&:blank?)
      return if cache_names.blank?
      clear_unstaged
      cache_names.each do |cache_name|
        uploader = blank_uploader
        uploader.retrieve_from_cache!(cache_name)
        @uploaders << uploader
      rescue CarrierWave::InvalidParameter
        # ignore
      end
      write_temporary_identifier
    end

    def remote_urls=(urls)
      if urls.nil?
        urls = []
      else
        urls = Array.wrap(urls).reject(&:blank?)
        return if urls.blank?
      end
      @remote_urls = urls

      clear_unstaged
      @remote_urls.zip(remote_request_headers || []) do |url, header|
        handle_error do
          uploader = blank_uploader
          uploader.download!(url, header || {})
          @uploaders << uploader
        end
      end
      write_temporary_identifier
    end

    def store!
      uploaders.each(&:store!)
    end

    def write_identifier
      return if record.frozen?

      clear! if remove?

      additions, remains = uploaders.partition(&:cached?)
      existing_identifiers = (@removed_uploaders + remains).map(&:identifier)
      additions.each do |uploader|
        uploader.deduplicate(existing_identifiers)
        existing_identifiers << uploader.identifier
      end
      @added_uploaders += additions

      record.write_uploader(serialization_column, identifier)
    end

    def urls(*args)
      uploaders.map { |u| u.url(*args) }
    end

    def blank?
      uploaders.none?(&:present?)
    end

    def remove=(value)
      @remove = value
      write_temporary_identifier
    end

    def remove?
      remove.present? && (remove.to_s !~ /\A0|false$\z/)
    end

    def remove!
      uploaders.each(&:remove!)
      clear!
    end

    def clear!
      @removed_uploaders += uploaders
      @remove = nil
      @uploaders = []
    end

    def reset_changes!
      @removed_uploaders = []
      @added_uploaders = []
    end

    def serialization_column
      option(:mount_on) || column
    end

    def remove_previous
      current_paths = uploaders.map(&:path)
      @removed_uploaders
        .reject {|uploader| current_paths.include?(uploader.path) }
        .each { |uploader| uploader.remove! if uploader.remove_previously_stored_files_after_update }
      reset_changes!
    end

    def remove_added
      current_paths = (@removed_uploaders + uploaders.select(&:staged)).map(&:path)
      @added_uploaders
        .reject {|uploader| current_paths.include?(uploader.path) }
        .each { |uploader| uploader.remove! }
      reset_changes!
    end

  private

    def option(name)
      self.uploader_options ||= {}
      self.uploader_options[name] ||= record.class.uploader_option(column, name)
    end

    def clear_unstaged
      @uploaders ||= []
      staged, unstaged = @uploaders.partition(&:staged)
      @uploaders = staged
      @removed_uploaders += unstaged
    end

    def handle_error
      yield
    rescue CarrierWave::DownloadError => e
      @download_errors << e
      raise e unless option(:ignore_download_errors)
    rescue CarrierWave::ProcessingError => e
      @processing_errors << e
      raise e unless option(:ignore_processing_errors)
    rescue CarrierWave::IntegrityError => e
      @integrity_errors << e
      raise e unless option(:ignore_integrity_errors)
    end

    def write_temporary_identifier
      return if record.frozen?

      record.write_uploader(serialization_column, temporary_identifier)
    end

    def temporary_identifiers
      if remove?
        []
      else
        uploaders.map { |uploader| uploader.temporary_identifier }
      end
    end
  end # Mounter
end # CarrierWave
