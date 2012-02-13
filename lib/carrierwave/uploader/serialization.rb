# encoding: utf-8

require "active_support/json"
require "active_support/core_ext/hash"

module CarrierWave
  module Uploader
    module Serialization
      extend ActiveSupport::Concern

      def serializable_hash
        {"url" => url}.merge Hash[versions.map { |name, version| [name, { "url" => version.url }] }]
      end

      def as_json(options=nil)
        Hash[mounted_as || "uploader", serializable_hash]
      end

      def to_json
        ActiveSupport::JSON.encode(as_json)
      end

      def to_xml
        serializable_hash.to_xml(:root => mounted_as || "uploader")
      end

    end
  end
end
