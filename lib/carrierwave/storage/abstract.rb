module CarrierWave
  module Storage

    ##
    # This file serves mostly as a specification for Storage engines. There is no requirement
    # that storage engines must be a subclass of this class. However, any storage engine must
    # conform to the following interface:
    #
    # The storage engine must respond to store!, taking an uploader object and a
    # CarrierWave::SanitizedFile as parameters. This method should do something to store
    # the given file, and then return an object.
    #
    # The storage engine must respond to retrieve!, taking an uploader object and an identifier
    # as parameters. This method should do retrieve and then return an object.
    #
    # The objects returned by store! and retrieve! both *must* respond to +identifier+, taking
    # no arguments. Identifier is a string that uniquely identifies this file and can be used
    # to retrieve it later.
    #
    class Abstract

      # Do something to destroy the file
      #
      # === Parameters
      #
      # [uploader (CarrierWave::Uploader)] an uploader object
      # [identifier (String)] uniquely identifies the file
      #
      # === Returns
      #
      # [bool] True if file was remove or false
      #
      def self.destroy!(uploader, identifier)
        false
      end
      
      ##
      # Do setup specific for this storage engine
      #
      def self.setup!; end

      ##
      # Do something to store the file
      #
      # === Parameters
      #
      # [uploader (CarrierWave::Uploader)] an uploader object
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [#identifier] an object
      #
      def self.store!(uploader, file)
        self.new
      end
      
      # Do something to retrieve the file
      #
      # === Parameters
      #
      # [uploader (CarrierWave::Uploader)] an uploader object
      # [identifier (String)] uniquely identifies the file
      #
      # === Returns
      #
      # [#identifier] an object
      #
      def self.retrieve!(uploader, identifier)
        self.new
      end
      
      ##
      # Should return a String that uniquely identifies this file and can be used to retrieve it from
      # the same storage engine later on.
      #
      # This is OPTIONAL
      #
      # === Returns
      #
      # [String] path to the file
      #
      def identifier; end

      ##
      # Should return the url where the file is publically accessible. If this is not set, then
      # it is assumed that the url is the path relative to the public directory.
      #
      # This is OPTIONAL
      #
      # === Returns
      #
      # [String] file's url
      #
      def url; end
      
      ##
      # Should return the path where the file is corrently located. This is OPTIONAL.
      #
      # This is OPTIONAL
      #
      # === Returns
      #
      # [String] path to the file
      #
      def path; end
      
    end # Abstract
  end # Storage
end # CarrierWave
