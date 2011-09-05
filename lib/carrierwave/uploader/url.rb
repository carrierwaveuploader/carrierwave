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
      # FIXME to_xml should work like to_json, but this is the best we've been able to do so far.
      # This hack fixes issue #337.
      #
      # === Returns
      #
      # [nil]
      #
      def to_xml(options = nil)
      end

    end # Url
  end # Uploader
end # CarrierWave
