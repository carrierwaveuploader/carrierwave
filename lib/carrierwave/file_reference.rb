module CarrierWave
  ##
  # A reference to a file, standing in for it when a condition has to be answered at
  # a point where only its name is known, such as when the path of a stored file is
  # being worked out. It tells what the name tells, and refuses the rest rather than
  # reaching for the file to find out.
  #
  class FileReference
    include CarrierWave::Utilities::FileName

    attr_reader :filename
    alias_method :original_filename, :filename
    alias_method :path, :filename

    def initialize(filename)
      @filename = filename
    end

    def content_type
      Marcel::MimeType.for(name: filename)
    end

    def blank?
      filename.blank?
    end

    def respond_to_missing?(*)
      true
    end

    def method_missing(name, *)
      raise CarrierWave::FileUnavailable, "##{name} is not available here, as this is a reference holding the name #{filename.inspect} and nothing more. " \
        "A condition given to `process convert:` has to be answerable from the filename alone, so that the resulting file extension can be worked out again when the file is retrieved."
    end
  end
end
