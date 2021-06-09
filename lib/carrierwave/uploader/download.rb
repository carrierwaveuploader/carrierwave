module CarrierWave
  module Uploader
    module Download
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Cache

      ##
      # Caches the file by downloading it from the given URL, using downloader.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      # [download_retry_count （Int）] Retry count when download failed
      # [remote_headers (Hash)] Request headers
      #
      def download!(uri, download_retry_count = 0, remote_headers = {})
        file = downloader.new(self).download(uri, download_retry_count, remote_headers)
        cache!(file)
      end
    end # Download
  end # Uploader
end # CarrierWave
