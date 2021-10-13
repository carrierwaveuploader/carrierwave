module CarrierWave
  module Utilities
    module FileName

      ##
      # Returns the part of the filename before the extension. So if a file is called 'test.jpeg'
      # this would return 'test'
      #
      # === Returns
      #
      # [String] the first part of the filename
      #
      def basename
        split_extension(filename)[0] if filename
      end

      ##
      # Returns the file extension
      #
      # === Returns
      #
      # [String] extension of file or "" if the file has no extension
      #
      def extension
        split_extension(filename)[1] if filename
      end

      private

      def split_extension(filename)
        # regular expressions to try for identifying extensions
        extension_matchers = [
          /\A(.+)\.(tar\.([glx]?z|bz2))\z/, # matches "something.tar.gz"
          /\A(.+)\.([^\.]+)\z/ # matches "something.jpg"
        ]

        extension_matchers.each do |regexp|
          if filename =~ regexp
            return $1, $2
          end
        end

        return filename, "" # In case we weren't able to split the extension
      end
    end # FileName
  end # Utilities
end # CarrierWave
