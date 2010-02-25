# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'
require 'right_aws'

if ENV['S3_SPEC']
  describe CarrierWave::Storage::RightS3 do
    before do
      @bucket = ENV['CARRIERWAVE_TEST_BUCKET']
      @uploader = mock('an uploader')
      @uploader.stub!(:s3_access_key_id).and_return(ENV["S3_ACCESS_KEY_ID"])
      @uploader.stub!(:s3_secret_access_key).and_return(ENV["S3_SECRET_ACCESS_KEY"])
      @uploader.stub!(:s3_bucket).and_return(@bucket)
      @uploader.stub!(:s3_access_policy).and_return('public-read')
      @uploader.stub!(:s3_cnamed).and_return(false)

      @storage = CarrierWave::Storage::RightS3.new(@uploader)
      @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
    end
  
    after do
      @storage.connection.delete(@bucket, 'uploads/bar.txt')
    end

    describe '#store!' do
      before do
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')
        @s3_file = @storage.store!(@file)
      end
    
      it "should upload the file to s3" do
        @storage.connection.get_object(@bucket, 'uploads/bar.txt').should == 'this is stuff'
      end
    
      it "should have a path" do
        @s3_file.path.should == 'uploads/bar.txt'
      end
    
      it "should have an Amazon URL" do
        @s3_file.url.should == "http://#{@bucket}.s3.amazonaws.com/uploads/bar.txt"
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
        lambda {@storage.connection.head(@bucket, 'uploads/bar.txt')}.should raise_error(RightAws::AwsError)
      end
    end
  
    describe '#retrieve!' do
      before do
        @storage.connection.put(@bucket, "uploads/bar.txt", "A test, 1234", {'a-amz-acl' => 'public-read'})
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
        @s3_file.url.should == "http://#{@bucket}.s3.amazonaws.com/uploads/bar.txt"
      end
    
      it "should be deletable" do
        @s3_file.delete
        lambda {@storage.connection.head(@bucket, 'uploads/bar.txt')}.should raise_error(RightAws::AwsError)
      end
    end

  end
end
