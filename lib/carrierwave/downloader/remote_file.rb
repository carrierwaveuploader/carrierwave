module CarrierWave
  module Downloader
    class RemoteFile
      attr_reader :file

      def initialize(file)
        @file = file.is_a?(String) ? StringIO.new(file) : file
      end

      def original_filename
        filename = filename_from_header || filename_from_uri
        mime_type = MiniMime.lookup_by_content_type(file.content_type)
        unless File.extname(filename).present? || mime_type.blank?
          filename = "#{filename}.#{mime_type.extension}"
        end
        filename
      end

      def respond_to?(*args)
        super || file.respond_to?(*args)
      end

      private

      def filename_from_header
        if file.meta.include? 'content-disposition'
          match = file.meta['content-disposition'].match(/filename=(?:"([^"]+)"|([^";]+))/)
          match[1].presence || match[2].presence
        end
      end

      def filename_from_uri
        CGI.unescape(File.basename(file.base_uri.path))
      end

      def method_missing(*args, &block)
        file.send(*args, &block)
      end
    end
  end
end

