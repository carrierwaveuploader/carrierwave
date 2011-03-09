# encoding: utf-8

module CarrierWave
  module Uploader
    module Url

      ##
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url
        if file.respond_to?(:url) and not file.url.blank?
          file.url
        elsif current_path
          File.expand_path(current_path).gsub(File.expand_path(root), '')
        end
      end

      alias_method :to_s, :url

      ##
      # === Returns
      #
      # [String] A JSON serializtion containing this uploader's URL
      #
      def as_json(options = nil)
        { :url => url, :versions => get_versions_for_json }
      end

      ##
      # === Returns
      #
      # [Hash] A hash of the versions urls associated with the uploader
      #    
      def get_versions_for_json
        version_items = {}
        versions.each do |name, v|
          version_items[v.version_name] =  {}
          version_items[v.version_name]['url'] = v.url
        end
        return version_items
      end
      
    end # Url
  end # Uploader
end # CarrierWave