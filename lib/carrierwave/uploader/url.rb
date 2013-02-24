# encoding: utf-8

module CarrierWave
  module Uploader
    module Url
      extend ActiveSupport::Concern
      include CarrierWave::Uploader::Configuration

      ##
      # === Parameters
      #
      # [Hash] optional, the query params (only AWS)
      #
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url(options = {})
        url =
          if file.respond_to?(:url) and not file.url.blank?
            file.method(:url).arity == 0 ? file.url : file.url(options)
          elsif file.respond_to?(:path)
            path = file.path.gsub(File.expand_path(root), '')

            if host = asset_host
              if host.respond_to? :call
                "#{host.call(file)}#{path}"
              else
                "#{host}#{path}"
              end
            else
              (base_path || "") + path
            end
          end

        uri_encode_url(url)
      end

      def to_s
        url || ''
      end

    private

      def uri_encode_url(url)
        if url = URI.parse(url)
          url.path = uri_encode_path(url.path)
          url.to_s
        end
      rescue URI::InvalidURIError
        nil
      end

      def uri_encode_path(path)
        # based on Ruby < 2.0's URI.encode
        safe_string = URI::REGEXP::PATTERN::UNRESERVED + '\/'
        unsafe = Regexp.new("[^#{safe_string}]", false)

        path.gsub(unsafe) do
          us = $&
          tmp = ''
          us.each_byte do |uc|
            tmp << sprintf('%%%02X', uc)
          end
          tmp
        end
      end

    end # Url
  end # Uploader
end # CarrierWave
