require 'open-uri'
require 'ssrf_filter'
require 'addressable'
require 'carrierwave/downloader/remote_file'

module CarrierWave
  module Downloader
    class Base
      include CarrierWave::Utilities::Uri

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
        @current_download_retry_count = 0
        headers = remote_headers.
          reverse_merge('User-Agent' => "CarrierWave/#{CarrierWave::VERSION}")
        uri = process_uri(url.to_s)
        begin
          if skip_ssrf_protection?(uri)
            response = OpenURI.open_uri(process_uri(url.to_s), headers)
          else
            request = nil
            if ::SsrfFilter::VERSION.to_f < 1.1
              response = SsrfFilter.get(uri, headers: headers) do |req|
                request = req
              end
            else
              response = SsrfFilter.get(uri, headers: headers, request_proc: ->(req) { request = req }) do |res|
                res.body # ensure to read body
              end
            end
            response.uri = request.uri
            response.value
          end
        rescue StandardError => e
          if @current_download_retry_count < @uploader.download_retry_count
            @current_download_retry_count += 1
            sleep @uploader.download_retry_wait_time
            retry
          else
            raise CarrierWave::DownloadError, "could not download file: #{e.message}"
          end
        end
        CarrierWave::Downloader::RemoteFile.new(response)
      end

      ##
      # Processes the given URL by parsing it, and escaping if necessary. Public to allow overriding.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      #
      def process_uri(source)
        uri = Addressable::URI.parse(source)
        uri.host = uri.normalized_host
        # Perform decode first, as the path is likely to be already encoded
        uri.path = encode_path(decode_uri(uri.path)) if uri.path =~ CarrierWave::Utilities::Uri::PATH_UNSAFE
        uri.query = encode_non_ascii(uri.query) if uri.query
        uri.fragment = encode_non_ascii(uri.fragment) if uri.fragment
        URI.parse(uri.to_s)
      rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
        raise CarrierWave::DownloadError, "couldn't parse URL: #{source}"
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
      #     class CarrierWave::Downloader::CustomDownloader < CarrierWave::Downloader::Base
      #       def skip_ssrf_protection?(uri)
      #         uri.hostname == 'localhost' && uri.port == 80
      #       end
      #     end
      #
      #     my_uploader.downloader = CarrierWave::Downloader::CustomDownloader
      #
      def skip_ssrf_protection?(uri)
        false
      end
    end
  end
end
