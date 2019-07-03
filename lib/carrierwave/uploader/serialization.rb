require "json"
require "active_support/core_ext/hash"

module CarrierWave
  module Uploader
    module Serialization
      extend ActiveSupport::Concern

      def serializable_hash(options = nil)
        {"url" => url}.merge Hash[versions.map { |name, version| [name.to_s, { "url" => version.url }] }]
      end

      def as_json(options=nil)
        serializable_hash
      end

      def to_json(options=nil)
        JSON.generate(as_json)
      end

      def to_xml(options={})
        merged_options = options.merge(:root => mounted_as || "uploader", :type => 'uploader')
        serializable_hash.to_xml(merged_options)
      end

      def to_base64
        {"data" => as_base64(url)}.merge Hash[versions.map { |name, version| [name.to_s, { "data" => as_base64(version.url) }] }]
      end

      private

      def as_base64(url)
        bytes = open(url) {|f| f.read }
        "data:image/png;base64," + Base64.strict_encode64(bytes)
      end

    end
  end
end
