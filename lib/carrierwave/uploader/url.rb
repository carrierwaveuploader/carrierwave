# encoding: utf-8

module CarrierWave
  module Uploader
    module Url
      extend ActiveSupport::Concern
      include CarrierWave::Uploader::Configuration

      ##
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url
        if file.respond_to?(:url) and not file.url.blank?
          file.url
        elsif current_path
          (base_path || "") + File.expand_path(current_path).gsub(File.expand_path(root), '')
        end
      end

      alias_method :to_s, :url

      ##
      # === Returns
      #
      # [Hash] the locations where this file and versions are accessible via a url
      #
      def as_json(options = nil)
        h = { :url => url }
        h.merge Hash[versions.map { |name, version| [name, { :url => version.url }] }]
      end

      ##
      # === Returns
      #
      # [XML] the locations where this file and versions are accessible via a url
      #
      def to_xml(options = nil)
        JSON.parse(self.to_json).to_xml
      end

    end # Url
  end # Uploader
end # CarrierWave
