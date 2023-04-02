require 'uri'

module CarrierWave
  module Utilities
    module Uri
      # based on Ruby < 2.0's URI.encode
      PATH_SAFE = URI::REGEXP::PATTERN::UNRESERVED + '\/'
      PATH_UNSAFE = Regexp.new("[^#{PATH_SAFE}]", false)
      NON_ASCII = /[^[:ascii:]]/.freeze

    private

      def encode_path(path)
        URI::DEFAULT_PARSER.escape(path, PATH_UNSAFE)
      end

      def encode_non_ascii(str)
        URI::DEFAULT_PARSER.escape(str, NON_ASCII)
      end

      def decode_uri(str)
        URI::DEFAULT_PARSER.unescape(str)
      end
    end # Uri
  end # Utilities
end # CarrierWave
