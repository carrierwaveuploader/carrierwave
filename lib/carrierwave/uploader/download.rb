require 'open-uri'

module CarrierWave
  module Uploader
    module Download
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Cache

      class RemoteFile
        def initialize(uri)
          @uri = uri
          @uri_params = to_hash(URI::decode_www_form(uri.query || ''))
        end

        def original_filename
          filename = filename_from_header || File.basename(file.base_uri.path)
          mime_type = MIME::Types[file.content_type].first
          unless File.extname(filename).present? || mime_type.blank?
            filename = "#{filename}.#{mime_type.extensions.first}"
          end
          filename
        end

        def respond_to?(*args)
          super or file.respond_to?(*args)
        end

        def http?
          @uri.scheme =~ /^https?$/
        end

      private

        def file
          if @file.blank?
            @file = Kernel.open(@uri.to_s, user_agent_header)
            @file = @file.is_a?(String) ? StringIO.new(@file) : @file
          end
          @file

        rescue StandardError => e
          raise CarrierWave::DownloadError, "could not download file: #{e.message}"
        end

        def user_agent_header
          {"User-Agent" => "CarrierWave/#{CarrierWave::VERSION}"}.
          merge(bearer_authorization_header)
        end

        def bearer_authorization_header
          if @uri_params['access_token']
            {'Authorization' => "Bearer #{@uri_params['access_token']}"}
          else
            {}
          end
        end

        def filename_from_header
          if file.meta.include? 'content-disposition'
            match = file.meta['content-disposition'].match(/filename="?([^"]+)/)
            return match[1] unless match.nil? || match[1].empty?
          end
        end

        def method_missing(*args, &block)
          file.send(*args, &block)
        end

        def to_hash(array)
          Hash[*array.flatten(1)]
        end
      end

      ##
      # Caches the file by downloading it from the given URL.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      #
      def download!(uri)
        processed_uri = process_uri(uri)
        file = RemoteFile.new(processed_uri)
        raise CarrierWave::DownloadError, "trying to download a file which is not served over HTTP" unless file.http?
        cache!(file)
      end

      ##
      # Processes the given URL by parsing and escaping it. Public to allow overriding.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      #
      def process_uri(uri)
        URI.parse(uri)
      rescue URI::InvalidURIError
        uri_parts = uri.split('?')
        # regexp from Ruby's URI::Parser#regexp[:UNSAFE], with [] specifically removed
        encoded_uri = URI.encode(uri_parts.shift, /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,]/)
        encoded_uri << '?' << URI.encode(uri_parts.join('?')) if uri_parts.any?
        URI.parse(encoded_uri) rescue raise CarrierWave::DownloadError, "couldn't parse URL"
      end

    end # Download
  end # Uploader
end # CarrierWave
