# encoding: utf-8

begin
  require 'fog'
rescue LoadError
  raise "You don't have the 'fog' gem installed"
end

module CarrierWave
  module Storage

    ##
    # Stores things using the "fog" gem.
    #
    # fog supports storing files with AWS, Google, Local and Rackspace
    #
    # You need to setup some options to configure your usage:
    #
    # [:fog_credentials]  credentials to for provider
    # [:fog_directory]    specifies name of directory to store data in
    # [:fog_host]         (optional) non-default host to serve files from
    # [:fog_public]       (optional) public readability, defaults to false
    #
    #
    # AWS credentials contain the following keys:
    #
    # [:aws_access_key_id]
    # [:aws_secret_access_key]
    # [:region]                 (optional) defaults to 'us-east-1'
    #
    #
    # Google credentials contain the following keys:
    # [:google_storage_access_key_id]
    # [:google_storage_secrete_access_key]
    #
    #
    # Local credentials contain the following keys:
    #
    # [:local_root]             local path to files
    #
    #
    # Rackspace credentials contain the following keys:
    #
    # [:rackspace_username]
    # [:rackspace_api_key]
    #
    #
    # A full example with AWS credentials:
    #     CarrierWave.configure do |config|
    #       config.fog_credentials = {
    #         :aws_access_key_id => 'xxxxxx',
    #         :aws_secret_access_key => 'yyyyyy',
    #         :provider => 'AWS'
    #       }
    #       config.fog_directory = 'directoryname'
    #       config.fog_public = true
    #     end
    #
    class Fog < Abstract

      ##
      # Store a file
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::Storage::Fog::File] the stored file
      #
      def store!(file)
        f = CarrierWave::Storage::Fog::File.new(uploader, self, uploader.store_path)
        f.store(file)
        f
      end

      ##
      # Retrieve a file
      #
      # === Parameters
      #
      # [identifier (String)] unique identifier for file
      #
      # === Returns
      #
      # [CarrierWave::Storage::Fog::File] the stored file
      #
      def retrieve!(identifier)
        CarrierWave::Storage::Fog::File.new(uploader, self, uploader.store_path(identifier))
      end

      def connection
        @connection ||= begin
          ::Fog::Storage.new(uploader.fog_credentials)
        end
      end

      class File

        attr_reader :path

        def content_type
          file.content_type
        end

        def delete
          file.destroy
        end

        def initialize(uploader, base, path)
          @uploader, @base, @path = uploader, base, path
        end

        def read
          file.body
        end

        def size
          file.content_length
        end

        def store(new_file)
          @file = directory.files.create({
            :body         => new_file.read,
            :content_type => new_file.content_type,
            :key          => path,
            :public       => @uploader.fog_public
          })
        end

        def public_url
          if host = @uploader.fog_host
            host << '/' << path
          else
            # avoid a get by just using local reference
            directory.files.new(:key => path).public_url
          end
        end

      private

        def connection
          @base.connection
        end

        def directory
          @directory ||= begin
            connection.directories.get(@uploader.fog_directory) || connection.directories.create(
              :key    => @uploader.fog_directory,
              :public => @uploader.fog_public
            )
          end
        end

        def file
          @file ||= directory.files.get(path)
        end

      end

    end # Fog

  end # Storage
end # CarrierWave
