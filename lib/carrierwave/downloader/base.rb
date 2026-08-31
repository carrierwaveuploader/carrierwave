require 'open-uri'
require 'ssrf_filter'
require 'addressable/uri'
require 'carrierwave/downloader/remote_file'

module CarrierWave
  module Downloader
    class Base
      include CarrierWave::Utilities::Uri

      # Leftovers from pasting, removed before parsing as in the first steps of
      # https://url.spec.whatwg.org/#concept-basic-url-parser
      LEADING_TRAILING_JUNK = /\A[\x00-\x20]+|[\x00-\x20]+\z/.freeze
      EMBEDDED_JUNK = /[\t\n\r]/.freeze
      # Matches a host name with an optional port, but not a scheme like 'http://' or 'data:'
      HOSTISH = /\A[[:alnum:]][[:alnum:]\-._]*(?::\d+)?(?:[\/?#]|\z)/.freeze
      DEFAULT_SCHEME = 'https'.freeze

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
            response = OpenURI.open_uri(uri, headers)
          else
            request = nil
            ssrf_options = @uploader.ssrf_filter_options || {}
            if ::SsrfFilter::VERSION.to_f < 1.1
              response = SsrfFilter.get(uri, headers: headers, **ssrf_options) do |req|
                request = req
              end
            else
              response = SsrfFilter.get(uri, headers: headers, request_proc: ->(req) { request = req }, **ssrf_options) do |res|
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
      # Never decodes, as that would make %2F and '/', %2B and '+' indistinguishable.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      #
      def process_uri(source)
        uri = Addressable::URI.parse(normalize_input(source))
        uri.host = uri.normalized_host
        uri.path = sanitize_component(uri.path, SANITIZE_PATH) if uri.path
        uri.query = sanitize_component(uri.query, SANITIZE_QUERY) if uri.query
        uri.fragment = sanitize_component(uri.fragment, SANITIZE_FRAGMENT) if uri.fragment
        URI.parse(uri.to_s)
      rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
        raise CarrierWave::DownloadError, "couldn't parse URL: #{source}"
      end

      ##
      # Cleans up a URL as pasted by an end user, since `remote_#{column}_url=` is meant to be
      # fed from a text field. Public to allow overriding.
      #
      # === Parameters
      #
      # [source (String)] The URL given by the user
      #
      def normalize_input(source)
        source = source.to_s.gsub(LEADING_TRAILING_JUNK, '').gsub(EMBEDDED_JUNK, '')

        return "#{DEFAULT_SCHEME}:#{source}" if source.start_with?('//')
        # Don't promote a local path like '/etc/passwd' into a URL
        return source if source.start_with?('/')
        return "#{DEFAULT_SCHEME}://#{source}" if source.match?(HOSTISH)

        source
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
        @uploader.skip_ssrf_protection
      end
    end
  end
end
