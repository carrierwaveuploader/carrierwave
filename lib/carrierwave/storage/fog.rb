# encoding: utf-8

require "fog"

module CarrierWave
  module Storage

    ##
    # Stores things using the "fog" gem.
    #
    # fog supports storing files with AWS, Google, Local and Rackspace
    #
    # You need to setup some options to configure your usage:
    #
    # [:fog_credentials]  host info and credentials for service
    # [:fog_directory]    specifies name of directory to store data in, assumed to already exist
    #
    # [:fog_attributes]                   (optional) additional attributes to set on files
    # [:fog_public]                       (optional) public readability, defaults to true
    # [:fog_authenticated_url_expiration] (optional) time (in seconds) that authenticated urls
    #   will be valid, when fog_public is false and provider is AWS or Google, defaults to 600
    # [:fog_use_ssl_for_aws]              (optional) #public_url will use https for the AWS generated URL]
    #
    #
    # AWS credentials contain the following keys:
    #
    # [:aws_access_key_id]
    # [:aws_secret_access_key]
    # [:region]                 (optional) defaults to 'us-east-1'
    #   :region should be one of ['eu-west-1', 'us-east-1', 'ap-southeast-1', 'us-west-1', 'ap-northeast-1']
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
      class << self
        def connection_cache
          @connection_cache ||= {}
        end
      end

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
          options = credentials = uploader.fog_credentials
          self.class.connection_cache[credentials] ||= ::Fog::Storage.new(options)
        end
      end

      class File
        include CarrierWave::Utilities::Uri

        ##
        # Current local path to file
        #
        # === Returns
        #
        # [String] a path to file
        #
        attr_reader :path

        ##
        # Return all attributes from file
        #
        # === Returns
        #
        # [Hash] attributes from file
        #
        def attributes
          file.attributes
        end

        ##
        # Return a temporary authenticated url to a private file, if available
        # Only supported for AWS, Rackspace and Google providers
        #
        # === Returns
        #
        # [String] temporary authenticated url
        #   or
        # [NilClass] no authenticated url available
        #
        def authenticated_url(options = {})
          if ['AWS', 'Google', 'Rackspace'].include?(@uploader.fog_credentials[:provider])
            # avoid a get by using local references
            local_directory = connection.directories.new(:key => @uploader.fog_directory)
            local_file = local_directory.files.new(:key => path)
            if @uploader.fog_credentials[:provider] == "AWS"
              local_file.url(::Fog::Time.now + @uploader.fog_authenticated_url_expiration, options)
            elsif @uploader.fog_credentials[:provider] == "Rackspace"
              connection.get_object_https_url(@uploader.fog_directory, path, ::Fog::Time.now + @uploader.fog_authenticated_url_expiration)
            else
              local_file.url(::Fog::Time.now + @uploader.fog_authenticated_url_expiration)
            end
          else
            nil
          end
        end

        ##
        # Lookup value for file content-type header
        #
        # === Returns
        #
        # [String] value of content-type
        #
        def content_type
          @content_type || file.content_type
        end

        ##
        # Set non-default content-type header (default is file.content_type)
        #
        # === Returns
        #
        # [String] returns new content type value
        #
        def content_type=(new_content_type)
          @content_type = new_content_type
        end

        ##
        # Remove the file from service
        #
        # === Returns
        #
        # [Boolean] true for success or raises error
        #
        def delete
          # avoid a get by just using local reference
          directory.files.new(:key => path).destroy
        end

        ##
        # Return extension of file
        #
        # === Returns
        #
        # [String] extension of file
        #
        def extension
          path.split('.').last
        end

        ##
        # deprecated: All attributes from file (includes headers)
        #
        # === Returns
        #
        # [Hash] attributes from file
        #
        def headers
          location = caller.first
          warning = "[yellow][WARN] headers is deprecated, use attributes instead[/]"
          warning << " [light_black](#{location})[/]"
          Formatador.display_line(warning)
          attributes
        end

        def initialize(uploader, base, path)
          @uploader, @base, @path = uploader, base, path
        end

        ##
        # Read content of file from service
        #
        # === Returns
        #
        # [String] contents of file
        def read
          file.body
        end

        ##
        # Return size of file body
        #
        # === Returns
        #
        # [Integer] size of file body
        #
        def size
          file.content_length
        end

        ##
        # Check if the file exists on the remote service
        #
        # === Returns
        #
        # [Boolean] true if file exists or false
        def exists?
          !!directory.files.head(path)
        end

        ##
        # Write file to service
        #
        # === Returns
        #
        # [Boolean] true on success or raises error
        def store(new_file)
          fog_file = new_file.to_file
          @content_type ||= new_file.content_type
          @file = directory.files.create({
            :body         => fog_file ? fog_file : new_file.read,
            :content_type => @content_type,
            :key          => path,
            :public       => @uploader.fog_public
          }.merge(@uploader.fog_attributes))
          fog_file.close if fog_file && !fog_file.closed?
          true
        end

        ##
        # Return a url to a public file, if available
        #
        # === Returns
        #
        # [String] public url
        #   or
        # [NilClass] no public url available
        #
        def public_url
          encoded_path = encode_path(path)
          if host = @uploader.asset_host
            if host.respond_to? :call
              "#{host.call(self)}/#{encoded_path}"
            else
              "#{host}/#{encoded_path}"
            end
          else
            # AWS/Google optimized for speed over correctness
            case @uploader.fog_credentials[:provider]
            when 'AWS'
              # check if some endpoint is set in fog_credentials
              if @uploader.fog_credentials.has_key?(:endpoint)
                "#{@uploader.fog_credentials[:endpoint]}/#{@uploader.fog_directory}/#{encoded_path}"
              else
                protocol = @uploader.fog_use_ssl_for_aws ? "https" : "http"
                # if directory is a valid subdomain, use that style for access
                if @uploader.fog_directory.to_s =~ /^(?:[a-z]|\d(?!\d{0,2}(?:\d{1,3}){3}$))(?:[a-z0-9\.]|(?![\-])|\-(?![\.])){1,61}[a-z0-9]$/
                  "#{protocol}://#{@uploader.fog_directory}.s3.amazonaws.com/#{encoded_path}"
                else
                  # directory is not a valid subdomain, so use path style for access
                  "#{protocol}://s3.amazonaws.com/#{@uploader.fog_directory}/#{encoded_path}"
                end
              end
            when 'Google'
              "https://commondatastorage.googleapis.com/#{@uploader.fog_directory}/#{encoded_path}"
            else
              # avoid a get by just using local reference
              directory.files.new(:key => path).public_url
            end
          end
        end

        ##
        # Return url to file, if avaliable
        #
        # === Returns
        #
        # [String] url
        #   or
        # [NilClass] no url available
        #
        def url(options = {})
          if !@uploader.fog_public
            authenticated_url(options)
          else
            public_url
          end
        end

        ##
        # Return file name, if available
        #
        # === Returns
        #
        # [String] file name
        #   or
        # [NilClass] no file name available
        #
        def filename(options = {})
          if file_url = url(options)
            URI.decode(file_url).gsub(/.*\/(.*?$)/, '\1')
          end
        end

      private

        ##
        # connection to service
        #
        # === Returns
        #
        # [Fog::#{provider}::Storage] connection to service
        #
        def connection
          @base.connection
        end

        ##
        # local reference to directory containing file
        #
        # === Returns
        #
        # [Fog::#{provider}::Directory] containing directory
        #
        def directory
          @directory ||= begin
            connection.directories.new(
              :key    => @uploader.fog_directory,
              :public => @uploader.fog_public
            )
          end
        end

        ##
        # lookup file
        #
        # === Returns
        #
        # [Fog::#{provider}::File] file data from remote service
        #
        def file
          @file ||= directory.files.head(path)
        end

      end

    end # Fog

  end # Storage
end # CarrierWave
