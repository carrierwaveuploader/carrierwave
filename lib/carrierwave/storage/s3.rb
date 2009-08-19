# encoding: utf-8

module CarrierWave
  module Storage

    ##
    # Uploads things to Amazon S3 webservices. It requies the aws/s3 gem. In order for
    # CarrierWave to connect to Amazon S3, you'll need to specify an access key id, secret key
    # and bucket
    #
    #     CarrierWave.config[:s3][:access_key_id] = "xxxxxx"
    #     CarrierWave.config[:s3][:secret_access_key] = "xxxxxx"
    #     CarrierWave.config[:s3][:bucket] = "my_bucket_name"
    #
    # You can also set the access policy for the uploaded files:
    #
    #     CarrierWave.config[:s3][:access] = :public_read
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
    # You can change the generated url to a cnamed domain by setting the cnamed config:
    #
    #     CarrierWave.config[:s3][:cnamed] = true
    #
    # No the resulting url will be
    #     
    #     http://bucket_name.domain.tld/path/to/file
    #
    # instead of
    #
    #     http://s3.amazonaws.com/bucket_name.domain.tld/path/to/file
    #
    class S3 < Abstract

      class File

        def initialize(path, identifier)
          @path = path
          @identifier = identifier
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
        # Returns the filename on S3
        #
        # === Returns
        #
        # [String] path to the file
        #
        def identifier
          @identifier
        end

        ##
        # Reads the contents of the file from S3
        #
        # === Returns
        #
        # [String] contents of the file
        #
        def read
          AWS::S3::S3Object.value @path, bucket
        end

        ##
        # Remove the file from Amazon S3
        #
        def delete
          AWS::S3::S3Object.delete @path, bucket
        end

        ##
        # Returns the url on Amazon's S3 service
        #
        # === Returns
        #
        # [String] file's url
        #
        def url
          if CarrierWave::config[:s3][:cnamed]
            ["http://", bucket, @path].compact.join('/')
          else
            ["http://s3.amazonaws.com", bucket, @path].compact.join('/')
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
          @s3_object ||= AWS::S3::S3Object.find(@path, bucket)
        end


      private

        def bucket
          CarrierWave::Storage::S3.bucket
        end

        def access
          CarrierWave::Storage::S3.access
        end

      end

      ##
      # === Returns
      #
      # [String] the bucket set in the config options
      #
      def self.bucket
        CarrierWave.config[:s3][:bucket]
      end

      ##
      # === Returns
      #
      # [Symbol] the access priviliges the uploaded files should have
      #
      def self.access
        CarrierWave.config[:s3][:access]
      end

      ##
      # Connect to Amazon S3
      #
      def self.setup!
        require 'aws/s3'
        AWS::S3::Base.establish_connection!(
          :access_key_id     => CarrierWave.config[:s3][:access_key_id],
          :secret_access_key => CarrierWave.config[:s3][:secret_access_key]
        )
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
        AWS::S3::S3Object.store(::File.join(uploader.store_path), file.read, self.class.bucket, :access => self.class.access)
        CarrierWave::Storage::S3::File.new(uploader.store_path, uploader.filename)
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
        CarrierWave::Storage::S3::File.new(uploader.store_path(identifier), identifier)
      end

    end # S3
  end # Storage
end # CarrierWave
