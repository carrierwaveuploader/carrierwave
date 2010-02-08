# encoding: utf-8
require 'right_aws'

module CarrierWave
  module Storage

    ##
    # Uploads things to Amazon S3 webservices using the RightAWS libraries (right_aws gem). 
    # In order for CarrierWave to connect to Amazon S3, you'll need to specify an access key id, secret key
    # and bucket
    #
    #     CarrierWave.configure do |config|
    #       config.s3_access_key_id = "xxxxxx"
    #       config.s3_secret_access_key = "xxxxxx"
    #       config.s3_bucket = "my_bucket_name"
    #     end
    #
    # The RightAWS::S3Interface is used directly as opposed to the normal RightAWS::S3::Bucket et.al. classes.
    # This gives much improved performance and avoids unnecessary requests.
    #
    # You can set the access policy for the uploaded files:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_access_policy = 'public-read'
    #     end
    #
    # The default is 'public-read'. For more options see:
    #
    # http://docs.amazonwebservices.com/AmazonS3/latest/RESTAccessPolicy.html#RESTCannedAccessPolicies
    #
    # You can change the generated url to a cnamed domain by setting the cnamed config:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_cnamed = true
    #       config.s3_bucket = 'bucketname.domain.tld'
    #     end
    #
    # Now the resulting url will be
    #     
    #     http://bucketname.domain.tld/path/to/file
    #
    # instead of
    #
    #     http://bucketname.domain.tld.s3.amazonaws.com/path/to/file
    #
    class RightS3 < Abstract

      class File

        def initialize(uploader, base, path)
          @uploader = uploader
          @path = path
          @base = base
        end

        ##
        # Returns the current path of the file on S3
        #
        # === Returns
        #
        # [String] A path
        #
        def path
          @path
        end

        ##
        # Reads the contents of the file from S3
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          result = connection.get(bucket, @path)
          @headers = result[:headers]
          result[:object]
        end

        ##
        # Remove the file from Amazon S3
        #
        def delete
          connection.delete(bucket, @path)
        end

        ##
        # Returns the url on Amazon's S3 service
        #
        # === Returns
        #
        # [String] file's url
        #
        def url
          if @uploader.s3_cnamed
            ["http://", @uploader.s3_bucket, "/", @path].compact.join
          else
            ["http://s3.amazonaws.com/", @uploader.s3_bucket, "/", @path].compact.join
          end
        end

        def content_type
          headers["content-type"]
        end

        #def content_disposition
        #  s3_object.content_disposition
        #end

        def store(file)
          connection.put(bucket, @path, file.read,
            'x-amz-acl' => @uploader.s3_access_policy,
            'content-type' => file.content_type
          )
        end

      private
      
        def headers
          @headers ||= {}
        end

        def bucket
          @uploader.s3_bucket
        end

        def connection
          @base.connection
        end

      end

      ##
      # Store the file on S3
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::Storage::RightS3::File] the stored file
      #
      def store!(file)
        f = CarrierWave::Storage::RightS3::File.new(uploader, self, uploader.store_path)
        f.store(file)
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
      # [CarrierWave::Storage::RightS3::File] the stored file
      #
      def retrieve!(identifier)
        CarrierWave::Storage::RightS3::File.new(uploader, self, uploader.store_path(identifier))
      end

      def connection
        @connection ||= RightAws::S3Interface.new(uploader.s3_access_key_id, uploader.s3_secret_access_key)
      end

    end # RightS3
  end # Storage
end # CarrierWave
