require "active_support/core_ext/hash/keys"

module CarrierWave
  module Uploader
    module Metadata
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Versions

      ##
      # Facts about the file which were determined when it was stored, as recorded in
      # the column given to the +metadata+ option of the mount. They are the answer to
      # questions the storage cannot answer, like whether a conditional version was
      # created, and they save asking it the ones it can.
      #
      # Returns an empty Hash when nothing was recorded, in which case the facts are
      # derived from the file and the uploader definition as they have always been.
      #
      # === Returns
      #
      # [Hash] the recorded facts
      #
      def metadata
        return @metadata || {} unless parent_version

        parent_version.metadata.dig('versions', self.class.version_names.last.to_s) || {}
      end

      def metadata=(metadata)
        @metadata = metadata&.deep_stringify_keys
      end

      ##
      # Collects the facts to record about the file being stored. Override to record
      # your own, merging them into the result of +super+.
      #
      # === Returns
      #
      # [Hash] the facts to record
      #
      def build_metadata
        {
          'filename' => full_filename(identifier),
          'size' => size,
          'content_type' => content_type,
          'versions' => active_versions.map { |name, version| [name.to_s, version.build_metadata] }.to_h
        }
      end

      ##
      # === Returns
      #
      # [Boolean] Whether what is stored gets recorded, which the mount decides
      #
      def metadata_recorded?
        model.class.respond_to?(:uploader_option) &&
          model.class.uploaders.has_key?(mounted_as) &&
          !!model.class.uploader_option(mounted_as, :metadata_column)
      end

      def size
        metadata['size'] || super
      end

      def content_type
        metadata['content_type'] || super
      end

      ##
      # The conditions decide which versions to create, so which ones were created is
      # settled once the file is stored. Consult the record instead of asking them
      # again, which is not only costly but can give a different answer.
      #
      def version_active?(name)
        recorded_versions = metadata['versions']
        return super unless recorded_versions

        versions.has_key?(name.to_sym) && recorded_versions.has_key?(name.to_s)
      end

      def cache!(*)
        @metadata = nil
        super
      end

      def recreate_versions!(*)
        @metadata = nil
        super
      end

    private

      def full_filename(for_file)
        return super unless for_file == identifier

        metadata['filename'] || super
      end
    end # Metadata
  end # Uploader
end # CarrierWave
