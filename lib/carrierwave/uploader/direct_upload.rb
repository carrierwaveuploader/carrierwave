module CarrierWave
  module Uploader
    module DirectUpload
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks
      include CarrierWave::Uploader::Configuration
      include CarrierWave::Uploader::Cache

      ##
      # Returns what a client needs to put a file into the cache itself, without the
      # bytes passing through the application. Assign the returned #cache_name to
      # #{column}_cache once the client is done, as with any cached file.
      #
      # === Parameters
      #
      # [filename (String)] the name the file is to be cached under
      # [expires_in (Integer)] seconds the upload stays possible, defaults to
      #                        fog_authenticated_url_expiration
      # [content_type (String)] the type the client has to send, if it is to be fixed
      #
      # === Returns
      #
      # [CarrierWave::DirectUpload] where and how to upload, and the name to hand back
      #
      def direct_upload(filename:, expires_in: nil, content_type: nil)
        filename = CarrierWave::SanitizedFile.new(filename).filename
        raise CarrierWave::InvalidParameter, "invalid filename" if filename.blank?

        upload = nil
        with_callbacks(:direct_upload, filename) do
          self.cache_id = CarrierWave.generate_cache_id
          self.original_filename = filename
          headers = content_type ? { 'Content-Type' => content_type } : {}

          upload = ::CarrierWave::DirectUpload.new(
            url: cache_storage.direct_upload_url(
              cache_path,
              expires_in: expires_in || fog_authenticated_url_expiration,
              headers: headers.dup # the storage may add its own
            ),
            headers: headers,
            cache_name: cache_name
          )
        end
        upload
      end
    end # DirectUpload
  end # Uploader
end # CarrierWave
