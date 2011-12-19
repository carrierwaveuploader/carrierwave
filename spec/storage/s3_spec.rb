# encoding: utf-8

require 'spec_helper'
require 'open-uri'

class S3SpecUploader < CarrierWave::Uploader::Base
  storage :s3
end

if ENV['REMOTE'] == 'true'
  describe CarrierWave::Storage::S3 do
    before do
      @bucket = "#{CARRIERWAVE_DIRECTORY}s3"
      @credentials = FOG_CREDENTIALS.select {|c| c[:provider] == 'AWS'}.first

      CarrierWave.configure do |config|
        config.reset_config
        config.s3_access_key_id     = @credentials[:aws_access_key_id]
        config.s3_secret_access_key = @credentials[:aws_secret_access_key]
        config.s3_bucket            = @bucket
        config.s3_access_policy     = :public_read
        config.s3_cnamed            = false
        config.s3_headers           = {'Expires' => 'Fri, 21 Jan 2021 16:51:06 GMT'}
        config.s3_region            = ENV["S3_REGION"] || 'us-east-1'
      end

      @uploader = S3SpecUploader.new
      @uploader.stub!(:store_path).and_return('uploads/bar.txt')

      @storage = CarrierWave::Storage::S3.new(@uploader)
      @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))

      @storage.connection.directories.get(@bucket) || @storage.connection.directories.create(:key => @bucket)
    end

    after do
      @storage.connection.delete_object(@bucket, 'uploads/bar.txt') unless @finished
    end

    describe 'general setup' do
      before(:each) do
        @storage.connection.put_object(@bucket, "uploads/bar.txt", "A test, 1234", {'a-amz-acl' => 'public-read'})
        @s3_file = CarrierWave::Storage::S3::File.new(@uploader, @storage, 'uploads/bar.txt')
      end

      it "should retrieve headers" do
        @s3_file.headers.should_not be_blank
      end

      it "should return filesize" do
        @s3_file.size.should == 12
      end
    end

    describe '#store!' do
      before do
        @s3_file = @storage.store!(@file)
      end

      it "should upload the file to s3" do
        @storage.connection.get_object(@bucket, 'uploads/bar.txt').body.should == 'this is stuff'
      end

      it "should have a path" do
        @s3_file.path.should == 'uploads/bar.txt'
      end

      context "without cnamed bucket" do
        it "should have a Euro supported Amazon URL" do
          @uploader.stub!(:s3_cnamed).and_return(false)
          @uploader.stub!(:s3_bucket).and_return('foo.bar')
          @s3_file.url.should == "http://foo.bar.s3.amazonaws.com/uploads/bar.txt"
        end
      end

      context "with cnamed bucket" do
        it "should have a CNAMED URL" do
          @uploader.stub!(:s3_cnamed).and_return(true)
          @uploader.stub!(:s3_bucket).and_return('foo.bar')
          @s3_file.url.should == 'http://foo.bar/uploads/bar.txt'
        end
      end

      it "should be deletable" do
        @s3_file.delete
        lambda {@storage.connection.head_object(@bucket, 'uploads/bar.txt')}.should raise_error(Excon::Errors::NotFound)
      end

      it "should set headers" do
        pending if Fog.mocking?
        headers = Excon.head("http://s3.amazonaws.com/#{@bucket}/uploads/bar.txt").headers
        headers["Expires"].should == 'Fri, 21 Jan 2021 16:51:06 GMT'
      end

      it "should return filesize" do
        @s3_file.size.should == 13
      end
    end

    describe '#retrieve!' do
      before do
        @storage.connection.put_object(@bucket, "uploads/bar.txt", "A test, 1234", {'a-amz-acl' => 'public-read'})
        @s3_file = @storage.retrieve!('bar.txt')
      end

      it "should retrieve the file contents from s3" do
        @s3_file.read.chomp.should == "A test, 1234"
      end

      it "should have a path" do
        @s3_file.path.should == 'uploads/bar.txt'
      end

      it "should have an Amazon URL" do
        @s3_file.url.should == "http://#{@bucket}.s3.amazonaws.com/uploads/bar.txt"
      end

      it "should be deletable" do
        @s3_file.delete
        lambda {@storage.connection.head_object(@bucket, 'uploads/bar.txt')}.should raise_error(Excon::Errors::NotFound)
      end

      it "should return filesize" do
        @s3_file.size.should == 12
      end
    end

    describe "#url for private content" do
      before do
        @uploader.stub!(:s3_access_policy).and_return(:authenticated_read)
        @storage.connection.put_object(@bucket, "uploads/bar.txt", "A test, 1234", {'a-amz-acl' => 'private'})
        @s3_file = @storage.retrieve!('bar.txt')
      end

      it "should return with Content-Disposition => 'attachment' when specified as query params" do
        headers = Excon.get(@s3_file.url(:query => {"response-content-disposition" => "attachment"})).headers
        headers["Content-Disposition"].should == "attachment"
      end
    end

    describe 'access policy' do
      context "with public read" do
        before do
          @uploader.stub!(:s3_access_policy).and_return(:public_read)
          @s3_file = @storage.store!(@file)
        end

        it "should be available at public URL" do
          pending if Fog.mocking?
          open(@s3_file.public_url).read.should == 'this is stuff'
        end

        it "should be available at generic URL" do
          pending if Fog.mocking?
          open(@s3_file.url).read.should == 'this is stuff'
        end
      end

      context "without public read" do
        before do
          @uploader.stub!(:s3_access_policy).and_return(:authenticated_read)
          @s3_file = @storage.store!(@file)
        end

        it "should be available at authenticated URL" do
          pending if Fog.mocking?
          open(@s3_file.authenticated_url).read.should == 'this is stuff'
        end

        it "should not be available at public URL" do
          pending if Fog.mocking?
          lambda do
            open(@s3_file.public_url)
          end.should raise_error(OpenURI::HTTPError, "403 Forbidden")
        end

        it "should be available at generic URL" do
          pending if Fog.mocking?
          open(@s3_file.url).read.should == 'this is stuff'
        end
      end
    end

    describe 's3 region' do
      before do
        @s3_file = @storage.store!(@file)
      end

      it "should use region-specific url for accessing aws" do
        host = URI.parse(@s3_file.authenticated_url).host
        case @uploader.s3_region
        when 'eu-west-1'
          host.should == 's3-eu-west-1.amazonaws.com'
        when 'us-east-1'
          host.should == 's3.amazonaws.com'
        when 'ap-southeast-1'
          host.should == 's3-ap-southeast-1.amazonaws.com'
        when 'us-west-1'
          host.should == 's3-us-west-1.amazonaws.com'
        end
      end
    end

    describe 'using http or https urls for amazon s3' do
      before do
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')
        @uploader.stub!(:s3_access_policy).and_return(:public_read)
        @s3_file = @storage.store!(@file)
      end

      it 'should use https if ssl enabled' do
        @uploader.stub!(:s3_use_ssl).and_return(true)
        URI.parse(@s3_file.url).scheme.should == 'https'
      end

      it 'should use http if ssl disabled' do
        @uploader.stub!(:s3_use_ssl).and_return(false)
        URI.parse(@s3_file.url).scheme.should == 'http'
      end
    end

    describe "#recreate_versions!" do
      before do
        @uploader_class = Class.new(CarrierWave::Uploader::Base)
        @uploader_class.class_eval{
          include CarrierWave::MiniMagick
          storage :s3

          process :resize_to_fit => [10, 10]

          version :foo do
            version :bar
          end
        }

        @versioned = @uploader_class.new
        @paths = ['portrait.jpg', 'foo_portrait.jpg', 'foo_bar_portrait.jpg']
        @versioned.store! File.open(file_path('portrait.jpg'))
      end

      after do
        FileUtils.rm_rf(public_path)

        @paths.each do |path|
          @storage.connection.delete_object(@bucket, "uploads/#{path}")
        end
      end

      it "should recreate versions stored remotely" do
        @paths.each do |path|
          @storage.connection.head_object(@bucket, "uploads/#{path}").status.should == 200
        end

        @storage.connection.delete_object(@bucket, "uploads/#{@paths[1]}")
        lambda { @storage.connection.head_object(@bucket, "uploads/#{@paths[1]}") }.should raise_error(Excon::Errors::NotFound)

        @versioned.recreate_versions!

        @paths.each do |path|
          @storage.connection.head_object(@bucket, "uploads/#{path}").status.should == 200
        end
      end
    end

    describe 'finished' do
      it "should delete the bucket when finished" do
        @finished = true
        @storage.connection.delete_bucket(@bucket)
      end
    end
  end
end
