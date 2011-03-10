# encoding: utf-8

require 'spec_helper'

if ENV['REMOTE'] == 'true'
  require 'cloudfiles'
  require 'net/http'

  class CloudfilesSpecUploader < CarrierWave::Uploader::Base
    storage :cloud_files
  end

  describe CarrierWave::Storage::CloudFiles do
    before do
      @credentials = FOG_CREDENTIALS.select {|c| c[:provider] == 'Rackspace'}.first
      @container_name = "#{CARRIERWAVE_DIRECTORY}cloudfiles"
      @connection = CloudFiles::Connection.new(@credentials[:rackspace_username], @credentials[:rackspace_api_key])
      @connection.create_container(@container_name) unless @connection.container_exists?(@container_name)
      @container = @connection.container(@container_name)
      @container.make_public

      CarrierWave.configure do |config|
        config.reset_config
        config.cloud_files_username = @credentials[:rackspace_username]
        config.cloud_files_api_key = @credentials[:rackspace_api_key]
        config.cloud_files_container = @container_name
      end

      @uploader = CloudfilesSpecUploader.new
      @storage = CarrierWave::Storage::CloudFiles.new(@uploader)
      @file = stub_tempfile('test.jpg', 'application/xml')
    end

    describe '#store!' do
      before do
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')
        @cloud_file = @storage.store!(@file)
      end

      it "should upload the file to Cloud Files" do
        @container.object('uploads/bar.txt').data.should == 'this is stuff'
      end

      it "should have a path" do
        @cloud_file.path.should == 'uploads/bar.txt'
      end

      it "should have an Rackspace URL" do
        # Don't check if its ".cdn." or ".cdn2." because they change these URLs
        @cloud_file.url.should =~ %r!http://(.*?).rackcdn.com/uploads/bar.txt!
      end

      it "should store the content type on Cloud Files" do
        # Recent addition of the charset to the response
        @cloud_file.content_type.should == 'application/xml; charset=UTF-8'
      end

      it "should be deletable" do
        @cloud_file.delete
        @container.object_exists?('uploads/bar.txt').should be_false
      end

    end

    describe '#retrieve!' do
      before do
        @container.create_object('uploads/bar.txt').write("A test, 1234")
        @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')

        @cloud_file = @storage.retrieve!('bar.txt')
      end

      it "should retrieve the file contents from Cloud Files" do
        @cloud_file.read.chomp.should == "A test, 1234"
      end

      it "should have a path" do
        @cloud_file.path.should == 'uploads/bar.txt'
      end

      it "should have an Rackspace URL" do
        # Don't check if its ".cdn." or ".cdn2." because they change these URLs
        @cloud_file.url.should =~ %r!http://(.*?).rackcdn.com/uploads/bar.txt!
      end

      it "should allow for configured CDN urls" do
        @uploader.stub!(:cloud_files_cdn_host).and_return("cdn.com")
        @cloud_file.url.should == 'http://cdn.com/uploads/bar.txt'
      end

      it "should be deletable" do
        @cloud_file.delete
        @container.object_exists?('uploads/bar.txt').should be_false
      end
    end

    describe 'finished' do
      it "should delete the container when finished" do
        @connection.delete_container(@container_name)
      end
    end
  end
end
