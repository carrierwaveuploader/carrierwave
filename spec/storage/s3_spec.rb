# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'
require 'aws/s3'
require 'net/http'

if ENV['S3_SPEC']
  describe CarrierWave::Storage::S3 do
    before do
      @uploader = mock('an uploader')
      @uploader.stub!(:s3_access_key_id).and_return(ENV["S3_ACCESS_KEY_ID"])
      @uploader.stub!(:s3_secret_access_key).and_return(ENV["S3_SECRET_ACCESS_KEY"])
      @uploader.stub!(:s3_bucket).and_return(ENV['CARRIERWAVE_TEST_BUCKET'])
      @uploader.stub!(:s3_access).and_return(:public_read)
      @uploader.stub!(:s3_cnamed).and_return(false)
      @uploader.stub!(:s3_headers).and_return({'Expires' => 'Fri, 21 Jan 2021 16:51:06 GMT'})

      @storage = CarrierWave::Storage::S3.new(@uploader)
      @file = stub_tempfile('test.jpg', 'application/xml')
    end
  
    after do
      AWS::S3::S3Object.delete('uploads/bar.txt', @uploader.s3_bucket)
    end

    describe '#store!' do
      before do
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')
        @s3_file = @storage.store!(@file)
      end
    
      it "should upload the file to s3" do
        AWS::S3::S3Object.value('uploads/bar.txt', @uploader.s3_bucket).should == 'this is stuff'
      end
    
      it "should have a path" do
        @s3_file.path.should == 'uploads/bar.txt'
      end
    
      it "should have an Amazon URL" do
        @s3_file.url.should == "http://s3.amazonaws.com/#{@uploader.s3_bucket}/uploads/bar.txt"
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
        AWS::S3::S3Object.exists?('uploads/bar.txt', @uploader.s3_bucket).should be_false
      end
      
      it "should store the content type on S3" do
        @s3_file.content_type.should == 'application/xml'
      end

      it "should set headers" do
        client = Net::HTTP.new("s3.amazonaws.com")
        headers = client.request_head(URI.parse(@s3_file.url).path)
        headers['Expires'].should == 'Fri, 21 Jan 2021 16:51:06 GMT'
      end
    end
  
    describe '#retrieve!' do
      before do
        AWS::S3::S3Object.store('uploads/bar.txt', "A test, 1234", @uploader.s3_bucket)
  
        @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')
        @s3_file = @storage.retrieve!('bar.txt')
      end

      it "should retrieve the file contents from s3" do
        @s3_file.read.chomp.should == "A test, 1234"
      end
    
      it "should have a path" do
        @s3_file.path.should == 'uploads/bar.txt'
      end
    
      it "should have an Amazon URL" do
        @s3_file.url.should == "http://s3.amazonaws.com/#{@uploader.s3_bucket}/uploads/bar.txt"
      end
    
      it "should be deletable" do
        @s3_file.delete
        AWS::S3::S3Object.exists?('uploads/bar.txt', @uploader.s3_bucket).should be_false
      end
    end

  end
end
