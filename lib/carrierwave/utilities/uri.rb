require 'uri'

module CarrierWave
  module Utilities
    module Uri
      # based on Ruby < 2.0's URI.encode
      PATH_SAFE = URI::RFC2396_REGEXP::PATTERN::UNRESERVED + '\/'
      PATH_UNSAFE = Regexp.new("[^#{PATH_SAFE}]", false)
      PATH_SAFE_WITH_PLUS = PATH_SAFE + '\+'
      PATH_UNSAFE_WITH_PLUS = Regexp.new("[^#{PATH_SAFE_WITH_PLUS}]", false)
      NON_ASCII = /[^[:ascii:]]/.freeze

    private

      def encode_path(path)
        URI::DEFAULT_PARSER.escape(path, PATH_UNSAFE)
      end

      def encode_non_ascii(str)
        URI::DEFAULT_PARSER.escape(str, NON_ASCII)
      end

      def encode_path_preserving_encoding(path, unsafe = PATH_UNSAFE)
        path.gsub(/(%[0-9a-fA-F]{2})|(#{unsafe})/) do
          $1 || $2.bytes.map { |byte| "%%%02X" % byte }.join
        end
      end
    end # Uri
  end # Utilities
end # CarrierWave
