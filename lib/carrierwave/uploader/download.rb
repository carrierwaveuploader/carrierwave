require 'open-uri'
require 'ssrf_filter'

module CarrierWave
  module Uploader
    module Download
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Cache

      class RemoteFile
        attr_reader :uri

        def initialize(uri, remote_headers = {}, skip_ssrf_protection: false)
          @uri = uri
          @remote_headers = remote_headers.reverse_merge('User-Agent' => "CarrierWave/#{CarrierWave::VERSION}")
          @file, @content_type, @headers = nil
          @skip_ssrf_protection = skip_ssrf_protection
        end

        def original_filename
          filename = filename_from_header || filename_from_uri
          mime_type = MIME::Types[content_type].first
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

        def content_type
          @content_type || 'application/octet-stream'
        end

        def headers
          @headers || {}
        end

        private

        def file
          if @file.blank?
            if @skip_ssrf_protection
              @file = (URI.respond_to?(:open) ? URI : Kernel).open(@uri.to_s, @remote_headers)
              @file = @file.is_a?(String) ? StringIO.new(@file) : @file
              @content_type = @file.content_type
              @headers = @file.meta
              @uri = @file.base_uri
            else
              request = nil
              response = SsrfFilter.get(@uri, headers: @remote_headers) do |req|
                request = req
              end
              response.value
              @file = StringIO.new(response.body)
              @content_type = response.content_type
              @headers = response
              @uri = request.uri
            end
          end
          @file

        rescue StandardError => e
          raise CarrierWave::DownloadError, "could not download file: #{e.message}"
        end

        def filename_from_header
          if headers['content-disposition']
            match = headers['content-disposition'].match(/filename="?([^"]+)/)
            return match[1] unless match.nil? || match[1].empty?
          end
        end

        def filename_from_uri
          URI::DEFAULT_PARSER.unescape(File.basename(@uri.path))
        end

        def method_missing(*args, &block)
          file.send(*args, &block)
        end
      end

      ##
      # Caches the file by downloading it from the given URL.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      # [remote_headers (Hash)] Request headers
      #
      def download!(uri, remote_headers = {})
        processed_uri = process_uri(uri)
        file = RemoteFile.new(processed_uri, remote_headers, skip_ssrf_protection: skip_ssrf_protection?(processed_uri))
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
        encoded_uri = URI::DEFAULT_PARSER.escape(uri_parts.shift, /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,]/)
        encoded_uri << '?' << URI::DEFAULT_PARSER.escape(uri_parts.join('?')) if uri_parts.any?
        URI.parse(encoded_uri) rescue raise CarrierWave::DownloadError, "couldn't parse URL"
      end

      ##
      # If this returns true, SSRF protection will be bypassed.
      # You can override this if you want to allow accessing specific local URIs that are not SSRF exploitable.
      #
      # === Parameters
      #
      # [uri (URI)] The URI where the remote file is stored
      #
      # === Examples
      #
      #     class MyUploader < CarrierWave::Uploader::Base
      #       def skip_ssrf_protection?(uri)
      #         uri.hostname == 'localhost' && uri.port == 80
      #       end
      #     end
      #
      def skip_ssrf_protection?(uri)
        false
      end
    end # Download
  end # Uploader
end # CarrierWave
