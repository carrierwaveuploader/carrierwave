# encoding: utf-8

require 'spec_helper'
require 'mongo'

shared_examples_for "a GridFS connection" do
  describe '#store!' do
    before do
      @uploader.stub!(:store_path).and_return('uploads/bar.txt')
      @grid_fs_file = @storage.store!(@file)
    end

    it "should upload the file to gridfs" do
      @grid.open('uploads/bar.txt', 'r').data.should == 'this is stuff'
    end

    it "should have the same path that it was stored as" do
      @grid_fs_file.path.should == 'uploads/bar.txt'
    end

    it "should not have a URL" do
      @grid_fs_file.url.should be_nil
    end

    it "should be deletable" do
      @grid_fs_file.delete
      lambda {@grid.open('uploads/bar.txt', 'r')}.should raise_error(Mongo::GridFileNotFound)
    end

    it "should store the content type on GridFS" do
      @grid_fs_file.content_type.should == 'application/xml'
    end

    it "should have a file length" do
      @grid_fs_file.file_length.should == 13
    end

  end

  describe '#retrieve!' do
    before do
      @grid.open('uploads/bar.txt', 'w') { |f| f.write "A test, 1234" }
      @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')
      @grid_fs_file = @storage.retrieve!('bar.txt')
    end

    it "should retrieve the file contents from gridfs" do
      @grid_fs_file.read.chomp.should == "A test, 1234"
    end

    it "should have the same path that it was stored as" do
      @grid_fs_file.path.should == 'uploads/bar.txt'
    end

    it "should not have a URL unless set" do
      @grid_fs_file.url.should be_nil
    end

    it "should return a URL if configured" do
      @uploader.stub!(:grid_fs_access_url).and_return("/image/show")
      @grid_fs_file.url.should == "/image/show/uploads/bar.txt"
    end

    it "should be deletable" do
      @grid_fs_file.delete
      lambda {@grid.open('uploads/bar.txt', 'r')}.should raise_error(Mongo::GridFileNotFound)
    end
  end

end

describe CarrierWave::Storage::GridFS do

  before do
    @database = Mongo::Connection.new('localhost', 27017).db('carrierwave_test')

    @uploader = mock('an uploader')
    @uploader.stub!(:grid_fs_access_url).and_return(nil)
  end

  context "when reusing an existing connection manually" do
    before do
      @uploader.stub!(:grid_fs_connection).and_return(@database)

      @grid = Mongo::GridFileSystem.new(@database)

      @storage = CarrierWave::Storage::GridFS.new(@uploader)
      @file = stub_tempfile('test.jpg', 'application/xml')
    end

    it_should_behave_like "a GridFS connection"

    # Calling #recreate_versions! on uploaders has been known to fail on
    # remotely hosted files. This is due to a variety of issues, but this test
    # makes sure that there's no unnecessary errors during the process
    describe "#recreate_versions!" do
      before do
        @uploader_class = Class.new(CarrierWave::Uploader::Base)
        @uploader_class.class_eval{
          include CarrierWave::MiniMagick
          storage :grid_fs

          process :resize_to_fit => [10, 10]
        }

        @versioned = @uploader_class.new
        @versioned.stub!(:grid_fs_connection).and_return(@database)

        @versioned.store! File.open(file_path('portrait.jpg'))
      end

      after do
        FileUtils.rm_rf(public_path)
      end

      it "recreates versions stored remotely without error" do
        lambda {
          @versioned.recreate_versions!
        }.should_not raise_error

        @versioned.should be_present
      end
    end


   describe "resize_to_fill" do
      before do
        @uploader_class = Class.new(CarrierWave::Uploader::Base)
        @uploader_class.class_eval{
          include CarrierWave::MiniMagick
          storage :grid_fs
        }
        
        @versioned = @uploader_class.new
        @versioned.stub!(:grid_fs_connection).and_return(@database)

        @versioned.store! File.open(file_path('portrait.jpg'))
      end

      after do
        FileUtils.rm_rf(public_path)
      end

      it "resizes the file with out error" do
        lambda {
          @versioned.resize_to_fill(200, 200)
        }.should_not raise_error
 
      end
    end
  end

  context "when setting a connection manually" do
    before do
      @uploader.stub!(:grid_fs_database).and_return("carrierwave_test")
      @uploader.stub!(:grid_fs_host).and_return("localhost")
      @uploader.stub!(:grid_fs_port).and_return(27017)
      @uploader.stub!(:grid_fs_username).and_return(nil)
      @uploader.stub!(:grid_fs_password).and_return(nil)
      @uploader.stub!(:grid_fs_connection).and_return(nil)

      @grid = Mongo::GridFileSystem.new(@database)

      @storage = CarrierWave::Storage::GridFS.new(@uploader)
      @file = stub_tempfile('test.jpg', 'application/xml')
    end

    it_should_behave_like "a GridFS connection"
  end

  after do
    @grid.delete('uploads/bar.txt')
  end

end
