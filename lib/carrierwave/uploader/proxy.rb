module CarrierWave
  module Uploader
    module Proxy

      ##
      # === Returns
      #
      # [Boolean] Whether the uploaded file is blank
      #
      def blank?
        file.blank?
      end

      ##
      # === Returns
      #
      # [String] the path where the file is currently located.
      #
      def current_path
        file.try(:path)
      end

      alias_method :path, :current_path

      ##
      # Returns a string that uniquely identifies the retrieved or last stored file
      #
      # === Returns
      #
      # [String] uniquely identifies a file
      #
      def identifier
        @identifier || (file && storage.try(:identifier))
      end

      ##
      # Returns a String which is to be used as a temporary value which gets assigned to the column.
      # The purpose is to mark the column that it will be updated. Finally before the save it will be
      # overwritten by the #identifier value, which is usually #filename.
      #
      # === Returns
      #
      # [String] a temporary_identifier, by default @original_filename is used
      #
      def temporary_identifier
        @original_filename || @identifier
      end

      ##
      # Read the contents of the file
      #
      # === Returns
      #
      # [String] contents of the file
      #
      def read(*args)
        file.try(:read, *args)
      end

      ##
      # Fetches the size of the currently stored/cached file
      #
      # === Returns
      #
      # [Integer] size of the file
      #
      def size
        file.try(:size) || 0
      end

      ##
      # Return the size of the file when asked for its length
      #
      # === Returns
      #
      # [Integer] size of the file
      #
      # === Note
      #
      # This was added because of the way Rails handles length/size validations in 3.0.6 and above.
      #
      def length
        size
      end

      ##
      # Read the content type of the file
      #
      # === Returns
      #
      # [String] content type of the file
      #
      def content_type
        file.try(:content_type)
      end

    end # Proxy
  end # Uploader
end # CarrierWave
