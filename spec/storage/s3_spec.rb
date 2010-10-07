# encoding: utf-8

require 'spec_helper'
require 'open-uri'

if ENV['S3_SPEC']
  describe CarrierWave::Storage::S3 do
    before do
      @bucket = ENV['CARRIERWAVE_TEST_BUCKET']
      @uploader = mock('an uploader')
      @uploader.stub!(:s3_access_key_id).and_return(ENV["S3_ACCESS_KEY_ID"])
      @uploader.stub!(:s3_secret_access_key).and_return(ENV["S3_SECRET_ACCESS_KEY"])
      @uploader.stub!(:s3_bucket).and_return(@bucket)
      @uploader.stub!(:s3_access_policy).and_return(:public_read)
      @uploader.stub!(:s3_cnamed).and_return(false)
      @uploader.stub!(:s3_headers).and_return({'Expires' => 'Fri, 21 Jan 2021 16:51:06 GMT'})

      @storage = CarrierWave::Storage::S3.new(@uploader)
      @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
    end

    after do
      @storage.connection.delete_object(@bucket, 'uploads/bar.txt')
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
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')
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
        client = Net::HTTP.new("#{@bucket}.s3.amazonaws.com")
        headers = client.request_head('/uploads/bar.txt')
        headers["Expires"].should == 'Fri, 21 Jan 2021 16:51:06 GMT'
      end

      it "should return filesize" do
        @s3_file.size.should == 13
      end
    end

    describe '#retrieve!' do
      before do
        @storage.connection.put_object(@bucket, "uploads/bar.txt", "A test, 1234", {'a-amz-acl' => 'public-read'})
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
        lambda {@storage.connection.head_object(@bucket, 'uploads/bar.txt')}.should raise_error(Excon::Errors::NotFound)
      end

      it "should return filesize" do
        @s3_file.size.should == 12
      end
    end

    describe 'access policy' do
      context "with public read" do
        before do
          @uploader.stub!(:store_path).and_return('uploads/bar.txt')
          @uploader.stub!(:s3_access_policy).and_return(:public_read)
          @s3_file = @storage.store!(@file)
        end

        it "should be available at public URL" do
          open(@s3_file.public_url).read.should == 'this is stuff'
        end

        it "should be availabel at generic URL" do
          open(@s3_file.url).read.should == 'this is stuff'
        end
      end

      context "with public read" do
        before do
          @uploader.stub!(:store_path).and_return('uploads/bar.txt')
          @uploader.stub!(:s3_access_policy).and_return(:authenticated_read)
          @s3_file = @storage.store!(@file)
        end

        it "should be available at authenticated URL" do
          open(@s3_file.authenticated_url).read.should == 'this is stuff'
        end

        it "should not be available at public URL" do
          lambda do
            open(@s3_file.public_url)
          end.should raise_error(OpenURI::HTTPError, "403 Forbidden")
        end

        it "should be available at generic URL" do
          open(@s3_file.url).read.should == 'this is stuff'
        end
      end
    end

  end
end
