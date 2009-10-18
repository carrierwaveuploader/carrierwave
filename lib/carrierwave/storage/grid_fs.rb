# encoding: utf-8
require 'mongo'
require 'mongo/gridfs'

module CarrierWave
  module Storage

    ##
    # The GridFS store uses MongoDB's GridStore file storage system to store files
    #
    class GridFS < Abstract

      class File

        def initialize(uploader, database, path)
          @database = database
          @path = path
          @uploader = uploader
        end

        def path
          nil
        end

        def url
          unless @uploader.grid_fs_access_url
            nil
          else
            [@uploader.grid_fs_access_url, @path].join("/")
          end
        end

        def read
          ::GridFS::GridStore.read(@database, @path)
        end

        def delete
          ::GridFS::GridStore.unlink(@database, @path)
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
        CarrierWave::Storage::GridFS::File.new(uploader, database, uploader.store_path)
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
        CarrierWave::Storage::GridFS::File.new(uploader, database, uploader.store_path(identifier))
      end

    private

      def database
        @connection ||= begin
          host = uploader.grid_fs_host
          database = uploader.grid_fs_database
          Mongo::Connection.new(host).db(database)
        end
      end

    end # File
  end # Storage
end # CarrierWave
