# encoding: utf-8

begin
  require 'fog'
rescue LoadError
  raise "You don't have the 'fog' gem installed"
end

module CarrierWave
  module Storage

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
          params = case uploader.fog_provider
          when 'AWS'
            {
              :aws_access_key_id      => uploader.fog_aws_access_key_id,
              :aws_secret_access_key  => uploader.fog_aws_secret_access_key,
              :region                 => uploader.fog_aws_region
            }
          when 'Google'
            {
              :google_storage_access_key_id     => uploader.fog_google_storage_access_key_id,
              :google_storage_secret_access_key => uploader.fog_google_storage_secret_access_key
            }
          when 'Local'
            {
              :local_root => uploader.fog_local_root
            }
          when 'Rackspace'
            {
              :rackspace_username => uploader.fog_rackspace_username,
              :rackspace_api_key  => uploader.fog_rackspace_api_key
            }
          end
          ::Fog::Storage.new(params.merge!(:provider => uploader.fog_provider))
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
          if @uploader.fog_host
            @uploader.fog_host << '/' << path
          else
            file.public_url
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
