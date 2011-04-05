# encoding: utf-8
require 'cloudfiles'

module CarrierWave
  module Storage

    ##
    # Uploads things to Rackspace Cloud Files webservices using the Rackspace libraries (cloudfiles gem).
    # In order for CarrierWave to connect to Cloud Files, you'll need to specify an username, api key
    # and container.  Optional arguments are config.cloud_files_snet (using the private internal 
    # Rackspace network for communication) and config.cloud_files_auth_url (for connecting to Rackspace's 
    # UK infrastructure or an OpenStack Swift installation)
    #
    #     CarrierWave.configure do |config|
    #       config.cloud_files_username = "xxxxxx"
    #       config.cloud_files_api_key = "xxxxxx"
    #       config.cloud_files_container = "my_container"
    #       config.cloud_files_auth_url = "https://lon.auth.api.rackspacecloud.com/v1.0"
    #       config.cloud_files_snet = true
    #     end
    #
    # You can optionally include your CDN host name in the configuration.
    # This is *highly* recommended, as without it every request requires a lookup
    # of this information.
    #
    #   config.cloud_files_cdn_host = "c000000.cdn.rackspacecloud.com"
    #
    #
    class CloudFiles < Abstract

      class File

        def initialize(uploader, base, path)
          @uploader = uploader
          @path = path
          @base = base
        end

        ##
        # Returns the current path/filename of the file on Cloud Files.
        #
        # === Returns
        #
        # [String] A path
        #
        def path
          @path
        end

        ##
        # Reads the contents of the file from Cloud Files
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          object = cf_container.object(@path)
          @content_type = object.content_type
          object.data
        end

        ##
        # Remove the file from Cloud Files
        #
        def delete
          begin
            cf_container.delete_object(@path)
          rescue ::CloudFiles::Exception::NoSuchObject
            # If the file's not there, don't panic
            nil
          end
        end

        ##
        # Returns the url on the Cloud Files CDN.  Note that the parent container must be marked as
        # public for this to work.
        #
        # === Returns
        #
        # [String] file's url
        #
        def url
          if @uploader.cloud_files_cdn_host
            "http://" + @uploader.cloud_files_cdn_host + "/" + @path
          else
            begin
              cf_container.object(@path).public_url
            rescue ::CloudFiles::Exception::NoSuchObject
              nil
            end
          end
        end

        def content_type
          cf_container.object(@path).content_type
        end

        def content_type=(new_content_type)
          headers["content-type"] = new_content_type
        end

        ##
        # Writes the supplied data into the object on Cloud Files.
        #
        # === Returns
        #
        # boolean
        #
        def store(data,headers={})
          object = cf_container.create_object(@path)
          object.write(data,headers)
        end

        private

          def headers
            @headers ||= {  }
          end

          def container
            @uploader.cloud_files_container
          end

          def connection
            @base.connection
          end

          def cf_connection
            config = {:username => @uploader.cloud_files_username, :api_key => @uploader.cloud_files_api_key}
            config[:auth_url] = @uploader.cloud_files_auth_url if @uploader.respond_to?(:cloud_files_auth_url)
            config[:snet] = @uploader.cloud_files_snet if @uploader.respond_to?(:cloud_files_snet)
            @cf_connection ||= ::CloudFiles::Connection.new(config)
          end

          def cf_container
            if @cf_container
              @cf_container
            else
              begin
                @cf_container = cf_connection.container(container)
              rescue NoSuchContainerException
                @cf_container = cf_connection.create_container(container)
                @cf_container.make_public
              end
              @cf_container
            end
          end


      end

      ##
      # Store the file on Cloud Files
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::Storage::CloudFiles::File] the stored file
      #
      def store!(file)
        cloud_files_options = {'Content-Type' => file.content_type}
        f = CarrierWave::Storage::CloudFiles::File.new(uploader, self, uploader.store_path)
        f.store(file.read,cloud_files_options)
        f
      end

      # Do something to retrieve the file
      #
      # @param [String] identifier uniquely identifies the file
      #
      # [identifier (String)] uniquely identifies the file
      #
      # === Returns
      #
      # [CarrierWave::Storage::CloudFiles::File] the stored file
      #
      def retrieve!(identifier)
        CarrierWave::Storage::CloudFiles::File.new(uploader, self, uploader.store_path(identifier))
      end


    end # CloudFiles
  end # Storage
end # CarrierWave
