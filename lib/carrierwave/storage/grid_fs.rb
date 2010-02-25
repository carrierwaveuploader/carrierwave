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

        def content_type
          ::GridFS::GridStore.open(@database, @path, 'r') { |f| return f.content_type }
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
        ::GridFS::GridStore.open(database, uploader.store_path, 'w', :content_type => file.content_type) do |f|
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
          port = uploader.grid_fs_port
          database = uploader.grid_fs_database
          username = uploader.grid_fs_username
          password = uploader.grid_fs_password
          db = Mongo::Connection.new(host, port).db(database)
          db.authenticate(username, password) if username && password
          db
        end
      end

    end # File
  end # Storage
end # CarrierWave
