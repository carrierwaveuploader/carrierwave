module Merb
  module Upload

    class SanitizedFile
    
      attr_accessor :file, :options
    
      def initialize(file, options = {})
        self.file = file
        self.options = options
      end
    
      ##
      # Returns the filename as is, without sanizting it.
      #
      # @return [String] the unsanitized filename
      #
      def original_filename
        return @original_filename if @original_filename
        if @file and @file.respond_to?(:original_filename)
          @file.original_filename
        elsif path
          File.basename(path)
        end
      end
      
      ##
      # Returns the filename, sanitized to strip out any evil characters.
      #
      # @return [String] the sanitized filename
      #
      def filename
        sanitize(original_filename) if original_filename
      end
      
      alias_method :identifier, :filename
      
      ##
      # Returns the part of the filename before the extension. So if a file is called 'test.jpeg'
      # this would return 'test'
      #
      # @return [String] the first part of the filename
      #
      def basename
        split_extension(filename)[0] if filename
      end
      
      ##
      # Returns the file extension
      #
      # @return [String] the extension
      #
      def extension
        split_extension(filename)[1] if filename
      end
    
      ##
      # Returns the file's size.
      #
      # @return [Integer] the file's size in bytes.
      #
      def size
        if @file.respond_to?(:size)
          @file.size 
        elsif path
          File.size(path)
        else 
          0
        end
      end
    
      ##
      # Returns the full path to the file. If the file has no path, it will return nil.
      #
      # @return [String, nil] the path where the file is located.
      #
      def path
        unless @file.blank?
          if string?
            File.expand_path(@file)
          elsif @file.respond_to?(:path) and not @file.path.blank?
            File.expand_path(@file.path)
          end
        end
      end
      
      ##
      # Returns true if the file is supplied as a pathname or as a string.
      #
      # @return [Boolean]
      #
      def string?
        !!((@file.is_a?(String) || @file.is_a?(Pathname)) && !@file.blank?)
      end
    
      ##
      # Checks if the file is valid and has a non-zero size
      #
      # @return [Boolean]
      #
      def empty?
        (@file.nil? && @path.nil?) || self.size.nil? || self.size.zero?
      end
    
      ##
      # Checks if the file exists
      #
      # @return [Boolean]
      #
      def exists?
        return File.exists?(self.path) if self.path
        return false
      end
      
      ##
      # Returns the contents of the file.
      #
      # @return [String] contents of the file
      #
      def read
        string? ? File.read(@file) : @file.read
      end
    
      ##
      # Moves the file to the given path
      #
      # @param [String] new_path The path where the file should be moved.
      #
      # --
      # FIXME: this currently copies the file, which is wrong.
      def move_to(new_path)
        new_path = File.expand_path(new_path)
        copy_file(new_path)
        self.file = new_path
      end
    
      ##
      # Creates a copy of this file and moves it to the given path. Returns the copy.
      #
      # @param [String] new_path The path where the file should be copied to.
      # @return [Merb::Upload::SanitizedFile] the location where the file will be stored.
      #
      def copy_to(new_path)
        copy = self.clone
        copy.move_to(new_path)
        return copy
      end
    
      ##
      # Removes the file from the filesystem.
      #
      def delete
        FileUtils.rm(self.path) if self.path
      end
    
      ##
      # Returns the content type of the file.
      #
      # @return [String] the content type of the file 
      #
      def content_type
        @file.content_type.chomp if @file.respond_to?(:content_type) and @file.content_type
      end
    
      private
      
      def file=(file)
        if file.is_a?(Hash)
          @file = file["tempfile"]
          @original_filename = file["filename"]
          @content_type = file["content_type"]
        else
          @file = file
          @original_filename = nil
          @content_type = nil
        end
      end
    
      def copy_file(new_path)
        unless self.empty?
          # create the directory if it doesn't exist
          FileUtils.mkdir_p(File.dirname(new_path)) unless File.exists?(File.dirname(new_path))
          # stringios don't have a path and can't be copied
          if not path and @file.respond_to?(:read)
            @file.rewind # Make sure we are at the beginning of the buffer
            File.open(new_path, "wb") { |f| f.write(@file.read) }
          elsif path != new_path
            FileUtils.cp(path, new_path)
          end
          File.chmod(@options[:permissions], new_path) if @options[:permissions]
          return true
        end
      end
    
      def sanitize(name)
        # Sanitize the filename, to prevent hacking
        name = File.basename(name.gsub("\\", "/")) # work-around for IE
        name.gsub!(/[^a-zA-Z0-9\.\-\+_]/,"_")
        name = "_#{name}" if name =~ /^\.+$/
        name = "unnamed" if name.size == 0
        return name.downcase
      end
    
      def split_extension(fn)
        # regular expressions to try for identifying extensions
        ext_regexps = [ 
          /^(.+)\.([^\.]{1,3}\.[^\.]{1,4})$/, # matches "something.tar.gz"
          /^(.+)\.([^\.]+)$/ # matches "something.jpg"
        ]
        ext_regexps.each do |regexp|
          if fn =~ regexp
            return $1, $2
          end
        end
        return fn, "" # In case we weren't able to split the extension
      end
    
    end
  end
end