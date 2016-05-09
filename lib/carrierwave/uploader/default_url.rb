module CarrierWave
  module Uploader
    module DefaultUrl

      def url(*args)
        super || determine_default_url(*args)
      end

      ##
      # Override this method in your uploader to provide a default url
      # in case no file has been cached/stored yet.
      #
      def default_url(*args); end

      private

      def determine_default_url(*args)
        path_or_url = default_url(*args)
        if asset_host && is_relative_url?(path_or_url)
          add_asset_host_to_path(path_or_url)
        else
          path_or_url
        end
      end

      def is_relative_url?(url)
        !url.match(/^https?:\/\//)
      end

    end # DefaultPath
  end # Uploader
end # CarrierWave
