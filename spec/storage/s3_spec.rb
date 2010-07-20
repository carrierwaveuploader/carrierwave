# encoding: utf-8

require 'spec_helper'
require 'aws'

if ENV['S3_SPEC']
  describe CarrierWave::Storage::S3 do
    before do
      @bucket = ENV['CARRIERWAVE_TEST_BUCKET']
      @uploader = mock('an uploader')
      @uploader.stub!(:s3_access_key_id).and_return(ENV["S3_ACCESS_KEY_ID"])
      @uploader.stub!(:s3_secret_access_key).and_return(ENV["S3_SECRET_ACCESS_KEY"])
      @uploader.stub!(:s3_bucket).and_return(@bucket)
      @uploader.stub!(:s3_access_policy).and_return('public-read')
      @uploader.stub!(:s3_cnamed).and_return(false)
      @uploader.stub!(:s3_multi_thread).and_return(true)
      @uploader.stub!(:s3_headers).and_return({'Expires' => 'Fri, 21 Jan 2021 16:51:06 GMT'})

      @storage = CarrierWave::Storage::S3.new(@uploader)
      @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
    end
  
    after do
      @storage.connection.delete(@bucket, 'uploads/bar.txt')
    end

    describe 'general setup' do
      before(:each) do
        @uploader.stub!(:s3_access_policy).and_return(nil)
        @uploader.stub!(:s3_access).and_return(nil)
        @s3_file = CarrierWave::Storage::S3::File.new(@uploader, @storage, 'uploads/bar.txt')
      end

      it "should use the default public-read access policy" do
        @s3_file.access_policy.should eql('public-read')
      end

      it "should use provided access policy" do
        @uploader.stub!(:s3_access_policy).and_return('bucket-owner-read')
        @s3_file.access_policy.should eql('bucket-owner-read')
      end

      it "should use old s3_access config if s3_access_policy not set" do
        @uploader.stub!(:s3_access).and_return(:public_read_write)
        @s3_file.access_policy.should eql('public-read-write')
      end
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
        lambda {@storage.connection.head(@bucket, 'uploads/bar.txt')}.should raise_error(Aws::AwsError)
      end
      
      it "should set headers" do
        client = Net::HTTP.new("#{@bucket}.s3.amazonaws.com")
        headers = client.request_head('/uploads/bar.txt')
        headers["Expires"].should == 'Fri, 21 Jan 2021 16:51:06 GMT'
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
        lambda {@storage.connection.head(@bucket, 'uploads/bar.txt')}.should raise_error(Aws::AwsError)
      end
    end

  end
end
