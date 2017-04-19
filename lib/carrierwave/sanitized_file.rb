require 'pathname'
require 'active_support/core_ext/string/multibyte'

begin
  # Use mime/types/columnar if available, for reduced memory usage
  require 'mime/types/columnar'
rescue LoadError
  require 'mime/types'
end

module CarrierWave

  ##
  # SanitizedFile is a base class which provides a common API around all
  # the different quirky Ruby File libraries. It has support for Tempfile,
  # File, StringIO, Merb-style upload Hashes, as well as paths given as
  # Strings and Pathnames.
  #
  # It's probably needlessly comprehensive and complex. Help is appreciated.
  #
  class SanitizedFile
    attr_reader :file

    class << self
      attr_writer :sanitize_regexp

      def sanitize_regexp
        @sanitize_regexp ||= /[^[:word:]\.\-\+]/
      end
    end

    def initialize(file)
      self.file = file
    end

    ##
    # Returns the filename (not the path) as is, without sanitizing it.
    #
    # === Returns
    #
    # [String] the unsanitized filename
    #
    def original_filename
      return @original_filename if @original_filename
      return @file.original_filename if @file && @file.respond_to?(:original_filename)
      return unless path
      uri = try_uri(path)
      File.basename(uri && uri.hostname ? uri.path : path)
    end

    ##
    # Returns the filename, sanitized to strip out any evil characters.
    #
    # === Returns
    #
    # [String] the sanitized filename
    #
    def filename
      sanitize(original_filename) if original_filename
    end

    alias_method :identifier, :filename

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
    # [String] the extension
    #
    def extension
      split_extension(filename)[1] if filename
    end

    ##
    # Returns the file's size.
    #
    # === Returns
    #
    # [Integer] the file's size in bytes.
    #
    def size
      if is_path?
        exists? ? File.size(path) : 0
      elsif @file.respond_to?(:size)
        @file.size
      elsif path
        exists? ? File.size(path) : 0
      else
        0
      end
    end

    ##
    # Returns the full path to the file. If the file has no path, it will return nil.
    #
    # === Returns
    #
    # [String, nil] the path where the file is located.
    #
    def path
      return if @file.blank?
      return File.expand_path(@file.path) if @file.respond_to?(:path) && !@file.path.blank?
      return unless is_path?
      uri = try_uri(@file)
      uri && uri.hostname ? uri.to_s : File.expand_path(@file)
    end

    ##
    # === Returns
    #
    # [Boolean] whether the file is supplied as a pathname or string.
    #
    def is_path?
      !!((@file.is_a?(String) || @file.is_a?(Pathname)) && !@file.blank?)
    end
    alias_method :path?, :is_path?

    ##
    # === Returns
    #
    # [Boolean] whether the file is valid and has a non-zero size
    #
    def empty?
      @file.nil? || self.size.nil? || (self.size.zero? && ! self.exists?)
    end

    ##
    # === Returns
    #
    # [Boolean] Whether the file exists
    #
    def exists?
      self.path.present? && File.exist?(self.path)
    end

    ##
    # Returns the contents of the file.
    #
    # === Returns
    #
    # [String] contents of the file
    #
    def read
      if @content
        @content
      elsif is_path?
        File.open(@file, "rb") {|file| file.read}
      else
        @file.try(:rewind)
        @content = @file.read
        @file.try(:close) unless @file.try(:closed?)
        @content
      end
    end

    ##
    # Moves the file to the given path
    #
    # === Parameters
    #
    # [new_path (String)] The path where the file should be moved.
    # [permissions (Integer)] permissions to set on the file in its new location.
    # [directory_permissions (Integer)] permissions to set on created directories.
    #
    def move_to(new_path, permissions=nil, directory_permissions=nil, keep_filename=false)
      return if self.empty?
      uri = try_uri(new_path)
      new_path = File.expand_path(new_path) unless uri && uri.hostname
      mkdir!(new_path, directory_permissions)
      move!(new_path)
      chmod!(new_path, permissions)
      if keep_filename
        self.file = {:tempfile => new_path, :filename => original_filename, :content_type => content_type}
      else
        self.file = {:tempfile => new_path, :content_type => content_type}
      end
      self
    end
    ##
    # Helper to move file to new path.
    #
    def move!(new_path)
      if exists?
        FileUtils.mv(path, new_path) unless new_path == path
      else
        File.open(new_path, "wb") { |f| f.write(read) }
      end
    end

    ##
    # Creates a copy of this file and moves it to the given path. Returns the copy.
    #
    # === Parameters
    #
    # [new_path (String)] The path where the file should be copied to.
    # [permissions (Integer)] permissions to set on the copy
    # [directory_permissions (Integer)] permissions to set on created directories.
    #
    # === Returns
    #
    # @return [CarrierWave::SanitizedFile] the location where the file will be stored.
    #
    def copy_to(new_path, permissions=nil, directory_permissions=nil)
      return if self.empty?
      uri = try_uri(new_path)
      new_path = File.expand_path(new_path) unless uri && uri.hostname
      mkdir!(new_path, directory_permissions)
      copy!(new_path)
      chmod!(new_path, permissions)
      self.class.new({:tempfile => new_path, :content_type => content_type})
    end

    ##
    # Helper to create copy of file in new path.
    #
    def copy!(new_path)
      if exists?
        FileUtils.cp(path, new_path) unless new_path == path
      else
        File.open(new_path, "wb") { |f| f.write(read) }
      end
    end

    ##
    # Removes the file from the filesystem.
    #
    def delete
      FileUtils.rm(self.path) if exists?
    end

    ##
    # Returns a File object, or nil if it does not exist.
    #
    # === Returns
    #
    # [File] a File object representing the SanitizedFile
    #
    def to_file
      return @file if @file.is_a?(File)
      File.open(path, "rb") if exists?
    end

    ##
    # Returns the content type of the file.
    #
    # === Returns
    #
    # [String] the content type of the file
    #
    def content_type
      return @content_type if @content_type
      if @file.respond_to?(:content_type) and @file.content_type
        @content_type = @file.content_type.to_s.chomp
      elsif path
        @content_type = ::MIME::Types.type_for(path).first.to_s
      end
    end

    ##
    # Sets the content type of the file.
    #
    # === Returns
    #
    # [String] the content type of the file
    #
    def content_type=(type)
      @content_type = type
    end

    ##
    # Used to sanitize the file name. Public to allow overriding for non-latin characters.
    #
    # === Returns
    #
    # [Regexp] the regexp for sanitizing the file name
    #
    def sanitize_regexp
      CarrierWave::SanitizedFile.sanitize_regexp
    end

  private

    def file=(file)
      if file.is_a?(Hash)
        @file = file["tempfile"] || file[:tempfile]
        @original_filename = file["filename"] || file[:filename]
        @content_type = file["content_type"] || file[:content_type] || file["type"] || file[:type]
      else
        @file = file
        @original_filename = nil
        @content_type = nil
      end
    end

    # create the directory if it doesn't exist
    def mkdir!(path, directory_permissions)
      options = {}
      options[:mode] = directory_permissions if directory_permissions
      FileUtils.mkdir_p(File.dirname(path), options) unless File.exist?(File.dirname(path))
    end

    def chmod!(path, permissions)
      File.chmod(permissions, path) if permissions
    end

    # Sanitize the filename, to prevent hacking
    def sanitize(name)
      name = name.tr("\\", "/") # work-around for IE
      uri = try_uri(name)
      name = uri.path if uri # only assign if parse was successful, otherwise treat as local
      name = File.basename(name)
      name = name.gsub(sanitize_regexp,"_")
      name = "_#{name}" if name =~ /\A\.+\z/
      name = "unnamed" if name.size == 0
      return name.mb_chars.to_s
    end

    ##
    # Returns URI if the String param can be parsed as URI, nil otherwise.  Swallows parse errors.
    #
    # === Returns
    #
    # [URI, nil] URI object
    #
    def try_uri(candidate)
      URI.parse(candidate)
    rescue URI::InvalidURIError
    end

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

  end # SanitizedFile
end # CarrierWave
