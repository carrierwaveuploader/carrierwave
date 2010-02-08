# encoding: utf-8
require 'aws/s3'

module CarrierWave
  module Storage

    ##
    # Uploads things to Amazon S3 webservices. It requies the aws/s3 gem. In order for
    # CarrierWave to connect to Amazon S3, you'll need to specify an access key id, secret key
    # and bucket:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_access_key_id = "xxxxxx"
    #       config.s3_secret_access_key = "xxxxxx"
    #       config.s3_bucket = "my_bucket_name"
    #     end
    #
    # You can also set the access policy for the uploaded files:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_access = :public
    #     end
    #
    # Possible values are the 'canned access control policies' provided in the aws/s3 gem,
    # they are:
    #
    # [:private]              No one else has any access rights.
    # [:public_read]          The anonymous principal is granted READ access.
    #                         If this policy is used on an object, it can be read from a
    #                         browser with no authentication.
    # [:public_read_write]    The anonymous principal is granted READ and WRITE access.
    # [:authenticated_read]   Any principal authenticated as a registered Amazon S3 user
    #                         is granted READ access.
    #
    # The default is :public_read, it should work in most cases.
    #
    # You can assign HTTP headers to be used when S3 serves your files:
    #
    #     CarrierWave.configure do |config|
    #       config.s3_headers = {"Content-Disposition" => "attachment; filename=foo.jpg;"}
    #     end
    #
    # You can also set the headers dynamically by overriding the s3_headers method:
    #
    #     class MyUploader < CarrierWave::Uploader::Base
    #       def s3_headers
    #         { "Expires" => 1.year.from_how.httpdate }
    #       end
    #     end
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
    #     http://s3.amazonaws.com/bucketname.domain.tld/path/to/file
    #
    class S3 < Abstract

      class File

        def initialize(uploader, path)
          @uploader = uploader
          @path = path
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
          AWS::S3::S3Object.value @path, @uploader.s3_bucket
        end

        ##
        # Remove the file from Amazon S3
        #
        def delete
          AWS::S3::S3Object.delete @path, @uploader.s3_bucket
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

        def about
          s3_object.about
        end

        def metadata
          s3_object.metadata
        end

        def content_type
          s3_object.content_type
        end

        def content_type=(new_content_type)
          s3_object.content_type = new_content_type
        end

        def content_disposition
          s3_object.content_disposition
        end

        def content_disposition=(new_disposition)
          s3_object.content_disposition = new_disposition
        end

        def store
          s3_object.store
        end

        def s3_object
          @s3_object ||= AWS::S3::S3Object.find(@path, @uploader.s3_bucket)
        end

      end

      ##
      # Store the file on S3
      #
      # === Parameters
      #
      # [file (CarrierWave::Storage::S3::File)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::Storage::S3] the stored file
      #
      def store!(file)
        connect!(uploader)
        s3_options = {:access => uploader.s3_access, :content_type => file.content_type}
        s3_options.merge!(uploader.s3_headers)
        AWS::S3::S3Object.store(uploader.store_path, file.read, uploader.s3_bucket, s3_options)
        CarrierWave::Storage::S3::File.new(uploader, uploader.store_path)
      end

      # Do something to retrieve the file
      #
      # @param [CarrierWave::Uploader] uploader an uploader object
      # @param [String] identifier uniquely identifies the file
      #
      # [identifier (String)] uniquely identifies the file
      #
      # === Returns
      #
      # [CarrierWave::Storage::S3::File] the stored file
      #
      def retrieve!(identifier)
        connect!(uploader)
        CarrierWave::Storage::S3::File.new(uploader, uploader.store_path(identifier))
      end

    private

      def connect!(uploader)
        AWS::S3::Base.establish_connection!(
          :access_key_id     => uploader.s3_access_key_id,
          :secret_access_key => uploader.s3_secret_access_key
        )
      end

    end # S3
  end # Storage
end # CarrierWave
