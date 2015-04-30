require 'open-uri'

module CarrierWave
  module Uploader
    # This module is the standard downloader
    module StandardDownloader
      extend self

      def download(uri)
        Kernel.open(uri.to_s,
                    "User-Agent" => "CarrierWave/#{CarrierWave::VERSION}")

        rescue StandardError => e
          raise CarrierWave::DownloadError, "could not download file: #{e.message}"
      end
    end
  end
end
