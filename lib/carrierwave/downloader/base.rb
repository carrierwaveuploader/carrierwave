require 'open-uri'
require 'carrierwave/downloader/remote_file'

module CarrierWave
  module Downloader
    class Base
      attr_reader :uploader

      def initialize(uploader)
        @uploader = uploader
      end

      ##
      # Downloads a file from given URL and returns a RemoteFile.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      # [remote_headers (Hash)] Request headers
      #
      def download(url, remote_headers = {})
        headers = remote_headers.
          reverse_merge('User-Agent' => "CarrierWave/#{CarrierWave::VERSION}")
        begin
          file = OpenURI.open_uri(process_uri(url.to_s), headers)
        rescue StandardError => e
          raise CarrierWave::DownloadError, "could not download file: #{e.message}"
        end
        CarrierWave::Downloader::RemoteFile.new(file)
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
    end
  end
end
