# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

if ENV['CLOUDFILES_SPEC']
  require 'cloudfiles'
  require 'net/http'

  describe CarrierWave::Storage::CloudFiles do
    before do
      @uploader = mock('an uploader')
      @uploader.stub!(:cloud_files_username).and_return(ENV["CLOUD_FILES_USER_NAME"])
      @uploader.stub!(:cloud_files_api_key).and_return(ENV["CLOUD_FILES_API_KEY"])
      @uploader.stub!(:cloud_files_container).and_return(ENV['CARRIERWAVE_TEST_CONTAINER'])
      @storage = CarrierWave::Storage::CloudFiles.new(@uploader)
      @file = stub_tempfile('test.jpg', 'application/xml')
      
      @cf = CloudFiles::Connection.new(ENV["CLOUD_FILES_USER_NAME"], ENV["CLOUD_FILES_API_KEY"])
      @container = @cf.container(@uploader.cloud_files_container)
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
        @cloud_file.url.should =~ %r!http://(.*?).cdn.cloudfiles.rackspacecloud.com/uploads/bar.txt!
      end
      
      it "should store the content type on Cloud Files" do
        @cloud_file.content_type.should == 'application/xml'
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
        @cloud_file.url.should =~ %r!http://(.*?).cdn.cloudfiles.rackspacecloud.com/uploads/bar.txt!
      end
    
      it "should be deletable" do
        @cloud_file.delete
        @container.object_exists?('uploads/bar.txt').should be_false
      end
    end

  end
end
