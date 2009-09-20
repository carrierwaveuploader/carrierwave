# encoding: utf-8
require 'mongo'

module CarrierWave
  module Storage

    ##
    # The GridFS store uses MongoDB's GridStore file storage system to store files
    #
    class GridFS < Abstract

      class File

        def initialize(database, path)
          @database = database
          @path = path
        end

        def path
          nil
        end

        def url
          unless CarrierWave.config[:grid_fs_access_url]
            nil
          else
            [CarrierWave.config[:grid_fs_access_url], @path].join("/")
          end
        end

        def read
          ::GridFS::GridStore.read(@database, @path)
        end

        def delete
          ::GridFS::GridStore.unlink(@database, @path)
        end

      end

      def database
        @connection ||= begin
          host = CarrierWave.config[:grid_fs_host]
          database = CarrierWave.config[:grid_fs_database]
          Mongo::Connection.new(host).db(database)
        end
      end

      ##
      # Store the file in MongoDB's GridFS GridStore
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def store!(file)
        ::GridFS::GridStore.open(database, uploader.store_path, 'w') do |f|
          f.write file.read
        end
        CarrierWave::Storage::GridFS::File.new(database, uploader.store_path)
      end

      ##
      # Retrieve the file from MongoDB's GridFS GridStore
      #
      # === Parameters
      #
      # [identifier (String)] the filename of the file
      #
      # === Returns
      #
      # [CarrierWave::Storage::GridFS::File] a sanitized file
      #
      def retrieve!(identifier)
        CarrierWave::Storage::GridFS::File.new(database, uploader.store_path(identifier))
      end

    end # File
  end # Storage
end # CarrierWave
