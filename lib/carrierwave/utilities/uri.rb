require 'uri'

module CarrierWave
  module Utilities
    module Uri
      # For encoding raw data into a URI component, where '%' is data and becomes '%25'.
      # based on Ruby < 2.0's URI.encode
      PATH_SAFE = URI::RFC2396_REGEXP::PATTERN::UNRESERVED + '\/'
      PATH_UNSAFE = Regexp.new("[^#{PATH_SAFE}]", false)

      # For repairing a string which is already a URI, following RFC 3986 per component.
      UNRESERVED = 'A-Za-z0-9\-._~'.freeze
      SUB_DELIMS = "!$&'()*+,;=".freeze
      PCHAR = "#{UNRESERVED}#{SUB_DELIMS}:@".freeze
      SANITIZE_PATH = Regexp.new("[#{PCHAR}/]").freeze
      # Also allows [ ] { } | \ ^, which browsers and URI.parse accept in a query
      SANITIZE_QUERY = Regexp.new("[#{PCHAR}/?\\[\\]{}|\\\\^]").freeze
      SANITIZE_FRAGMENT = Regexp.new("[#{PCHAR}/?]").freeze

      PERCENT_ENCODED = /%[0-9a-fA-F]{2}/.freeze

    module_function

      # Not idempotent, as '%' is escaped to '%25' every time
      def encode_path(path)
        URI::DEFAULT_PARSER.escape(path, PATH_UNSAFE)
      end

      # Only for strings not sent over the wire, like a filename to be shown to the user.
      # CGI.unescape is for form encoding and would turn '+' into a space.
      def decode_path(str)
        URI::DEFAULT_PARSER.unescape(str)
      end

      # Escapes only what cannot appear in the component, leaving existing %XX alone.
      # Decoding first would make %2F and '/', %2B and '+' indistinguishable.
      def sanitize_component(str, allowed)
        str.gsub(/(#{PERCENT_ENCODED})|(.)/m) do
          $1 || ($2.match?(allowed) ? $2 : escape_octets($2))
        end
      end

      def escape_octets(str)
        str.b.bytes.map { |byte| format('%%%02X', byte) }.join
      end
    end # Uri
  end # Utilities
end # CarrierWave
