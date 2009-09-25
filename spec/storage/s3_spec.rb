# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'
require 'aws/s3'

if ENV['S3_SPEC']
  describe CarrierWave::Storage::S3 do
    before do
      @uploader = mock('an uploader')
      @uploader.stub!(:s3_access_key_id).and_return(ENV["S3_ACCESS_KEY_ID"])
      @uploader.stub!(:s3_secret_access_key).and_return(ENV["S3_SECRET_ACCESS_KEY"])
      @uploader.stub!(:s3_bucket).and_return('carrierwave_test')
      @uploader.stub!(:s3_access).and_return(:public_read)
      @uploader.stub!(:s3_cnamed).and_return(false)

      @storage = CarrierWave::Storage::S3.new(@uploader)
      @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
    end
  
    after do
      AWS::S3::S3Object.delete('uploads/bar.txt', 'carrierwave_test')
    end

    describe '#store!' do
      before do
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')
        @s3_file = @storage.store!(@file)
      end
    
      it "should upload the file to s3" do
        AWS::S3::S3Object.value('uploads/bar.txt', 'carrierwave_test').should == 'this is stuff'
      end
    
      it "should have a path" do
        @s3_file.path.should == 'uploads/bar.txt'
      end
    
      it "should have an Amazon URL" do
        @s3_file.url.should == 'http://s3.amazonaws.com/carrierwave_test/uploads/bar.txt'
      end
    
      it "should be deletable" do
        @s3_file.delete
        AWS::S3::S3Object.exists?('uploads/bar.txt', 'carrierwave_test').should be_false
      end
    end
  
    describe '#retrieve!' do
      before do
        AWS::S3::S3Object.store('uploads/bar.txt', "A test, 1234", 'carrierwave_test')
  
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
        @s3_file.url.should == 'http://s3.amazonaws.com/carrierwave_test/uploads/bar.txt'
      end
    
      it "should be deletable" do
        @s3_file.delete
        AWS::S3::S3Object.exists?('uploads/bar.txt', 'carrierwave_test').should be_false
      end
    end

  end
end
