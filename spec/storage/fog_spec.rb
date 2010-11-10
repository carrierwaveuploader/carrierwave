# encoding: utf-8

require 'spec_helper'
require 'open-uri'

require 'fog'

if ENV['FOG_MOCK'] == 'true'
  Fog.mock!
end

if ENV['PROVIDER']
  describe CarrierWave::Storage::Fog do
    describe ENV['PROVIDER'] do
      before do
        @bucket = ENV['CARRIERWAVE_TEST_BUCKET']
        @uploader = mock('an uploader')
        @uploader.stub!(:fog_directory).and_return(@bucket)
        @uploader.stub!(:fog_host).and_return(nil)
        @uploader.stub!(:fog_public).and_return(true)
        @uploader.stub!(:fog_provider).and_return(ENV['PROVIDER'])
        case ENV['PROVIDER']
        when 'AWS'
          @uploader.stub!(:fog_aws_access_key_id).and_return(ENV['S3_ACCESS_KEY_ID'])
          @uploader.stub!(:fog_aws_secret_access_key).and_return(ENV['S3_SECRET_ACCESS_KEY'])
          @uploader.stub!(:fog_aws_region).and_return(ENV['S3_REGION'] || 'us-east-1')
        when 'Google'
          @uploader.stub!(:fog_google_storage_access_key_id).and_return(ENV['GOOGLE_STORAGE_ACCESS_KEY_ID'])
          @uploader.stub!(:fog_google_storage_secret_access_key).and_return(ENV['GOOGLE_STORAGE_SECRET_ACCESS_KEY'])
        when 'Local'
          @uploader.stub!(:fog_local_root).and_return(ENV['LOCAL_ROOT'])
        when 'Rackspace'
          @uploader.stub!(:fog_rackspace_username).and_return(ENV['RACKSPACE_USERNAME'])
          @uploader.stub!(:fog_rackspace_api_key).and_return(ENV['RACKSPACE_API_KEY'])
        end
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')

        @storage = CarrierWave::Storage::Fog.new(@uploader)
        @directory = @storage.connection.directories.new(:key => @bucket)
        @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
      end

      describe '#store!' do
        before do
          @uploader.stub!(:store_path).and_return('uploads/bar.txt')
          @fog_file = @storage.store!(@file)
        end

        it "should upload the file" do
          @directory.files.get('uploads/bar.txt').body.should == 'this is stuff'
        end

        it "should have a path" do
          @fog_file.path.should == 'uploads/bar.txt'
        end

        context "without fog_host" do
          it "should have a public_url" do
            pending if ENV['PROVIDER'] == 'Local'
            @fog_file.public_url.should_not be_nil
          end
        end

        context "with fog_host" do
          it "should have a fog_host rooted url" do
            @uploader.stub!(:fog_host).and_return('http://foo.bar')
            @fog_file.public_url.should == 'http://foo.bar/uploads/bar.txt'
          end
        end

        it "should return filesize" do
          @fog_file.size.should == 13
        end

        it "should be deletable" do
          @fog_file.delete
          @directory.files.head('uploads/bar.txt').should == nil
        end
      end

      describe '#retrieve!' do
        before do
          @directory.files.create(:key => 'uploads/bar.txt', :body => 'A test, 1234', :public => true)
          @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')
          @fog_file = @storage.retrieve!('bar.txt')
        end

        it "should retrieve the file contents" do
          @fog_file.read.chomp.should == "A test, 1234"
        end

        it "should have a path" do
          @fog_file.path.should == 'uploads/bar.txt'
        end

        it "should have a public url" do
          pending if ENV['PROVIDER'] == 'Local'
          @fog_file.public_url.should_not be_nil
        end

        it "should return filesize" do
          @fog_file.size.should == 12
        end

        it "should be deletable" do
          @fog_file.delete
          @directory.files.head('uploads/bar.txt').should == nil
        end
      end

      describe 'fog_public' do
        after do
          @directory.files.get('uploads/bar.txt').destroy
          @directory.destroy
        end

        context "true" do
          before do
            @fog_file = @storage.store!(@file)
          end

          it "should be available at public URL" do
            pending if ENV['PROVIDER'] == 'Local'
            open(@fog_file.public_url).read.should == 'this is stuff'
          end
        end

        context "false" do
          before do
            @uploader.stub!(:fog_public).and_return(false)
            @fog_file = @storage.store!(@file)
          end

          it "should not be available at public URL" do
            pending if ENV['PROVIDER'] == 'Local'
            @fog_file.public_url.should be_nil
          end
        end
      end
    end
  end
end
