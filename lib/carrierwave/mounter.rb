module CarrierWave

  # this is an internal class, used by CarrierWave::Mount so that
  # we don't pollute the model with a lot of methods.
  class Mounter #:nodoc:
    attr_reader :column, :record, :remote_url, :integrity_error, :processing_error, :download_error
    attr_accessor :remove

    def initialize(record, column, options={})
      @record = record
      @column = column
      @options = record.class.uploader_options[column]
    end

    def write_identifier
      return if record.frozen?

      if remove?
        record.write_uploader(serialization_column, nil)
      elsif uploader.identifier.present?
        record.write_uploader(serialization_column, uploader.identifier)
      end
    end

    def identifier
      record.read_uploader(serialization_column)
    end

    def uploader
      @uploader ||= record.class.uploaders[column].new(record, column)
      @uploader.retrieve_from_store!(identifier) if @uploader.blank? && identifier.present?

      @uploader
    end

    def cache(new_file)
      uploader.cache!(new_file)
      @integrity_error = nil
      @processing_error = nil
    rescue CarrierWave::IntegrityError => e
      @integrity_error = e
      raise e unless option(:ignore_integrity_errors)
    rescue CarrierWave::ProcessingError => e
      @processing_error = e
      raise e unless option(:ignore_processing_errors)
    end

    def cache_name
      uploader.cache_name
    end

    def cache_name=(cache_name)
      uploader.retrieve_from_cache!(cache_name) unless uploader.cached?
    rescue CarrierWave::InvalidParameter
    end

    def remote_url=(url)
      return if url.blank?

      @remote_url = url
      @download_error = nil
      @integrity_error = nil

      uploader.download!(url)

    rescue CarrierWave::DownloadError => e
      @download_error = e
      raise e unless option(:ignore_download_errors)
    rescue CarrierWave::ProcessingError => e
      @processing_error = e
      raise e unless option(:ignore_processing_errors)
    rescue CarrierWave::IntegrityError => e
      @integrity_error = e
      raise e unless option(:ignore_integrity_errors)
    end

    def store!
      return if uploader.blank?

      if remove?
        uploader.remove!
      else
        uploader.store!
      end
    end

    def url(*args)
      uploader.url(*args)
    end

    def blank?
      uploader.blank?
    end

    def remove?
      remove.present? && remove !~ /\A0|false$\z/
    end

    def remove!
      uploader.remove!
    end

    def serialization_column
      option(:mount_on) || column
    end

    attr_accessor :uploader_options

  private

    def option(name)
      self.uploader_options ||= {}
      self.uploader_options[name] ||= record.class.uploader_option(column, name)
    end

  end # Mounter
end # CarrierWave
