module CarrierWave
  module Storage
    ##
    # Uploads things to Amazon S3 webservices
    #
    class S3 < Abstract
      
      def initialize(bucket, store_dir, identifier)
        @bucket = bucket
        @store_dir = store_dir
        @identifier = identifier
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
      # @return [String] the bucket set in the config options
      # 
      def self.bucket
        CarrierWave.config[:s3][:bucket]
      end
      
      ##
      # @return [Symbol] the access priviliges the uploaded files should have
      #
      def self.access
        CarrierWave.config[:s3][:access]
      end
      
      ##
      # Store the file on S3
      #
      # @param [CarrierWave::Uploader] uploader an uploader object
      # @param [CarrierWave::SanitizedFile] file the file to store
      #
      # @return [#identifier] an object
      #
      def self.store!(uploader, file)
        AWS::S3::S3Object.store(::File.join(uploader.store_dir, uploader.filename), file.read, bucket, :access => access)
        self.new(bucket, uploader.store_dir, uploader.filename)
      end
      
      # Do something to retrieve the file
      #
      # @param [CarrierWave::Uploader] uploader an uploader object
      # @param [String] identifier uniquely identifies the file
      #
      # @return [#identifier] an object
      #
      def self.retrieve!(uploader, identifier)
        self.new(bucket, uploader.store_dir, identifier)
      end
      
      ##
      # Returns the filename on S3
      #
      # @return [String] path to the file
      #
      def identifier
        @identifier
      end

      ##
      # Returns the url on Amazon's S3 service
      #
      # @return [String] file's url
      #
      def url
        "http://s3.amazonaws.com/#{self.class.bucket}/#{@store_dir}/#{@identifier}"
      end
      
    end # S3
  end # Storage
end # CarrierWave