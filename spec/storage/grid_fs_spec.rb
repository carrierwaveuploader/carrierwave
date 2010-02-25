# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe CarrierWave::Storage::GridFS do

  before do
    @database = Mongo::Connection.new('localhost', 27017).db('carrierwave_test')
    @uploader = mock('an uploader')
    @uploader.stub!(:grid_fs_database).and_return("carrierwave_test")
    @uploader.stub!(:grid_fs_host).and_return("localhost")
    @uploader.stub!(:grid_fs_port).and_return(27017)
    @uploader.stub!(:grid_fs_access_url).and_return(nil)
    @uploader.stub!(:grid_fs_username).and_return(nil)
    @uploader.stub!(:grid_fs_password).and_return(nil)

    @storage = CarrierWave::Storage::GridFS.new(@uploader)
    @file = stub_tempfile('test.jpg', 'application/xml')
  end
  
  after do
    GridFS::GridStore.unlink(@database, 'uploads/bar.txt')
  end

  describe '#store!' do
    before do
      @uploader.stub!(:store_path).and_return('uploads/bar.txt')
      @grid_fs_file = @storage.store!(@file)
    end
    
    it "should upload the file to gridfs" do
      GridFS::GridStore.read(@database, 'uploads/bar.txt').should == 'this is stuff'
    end
    
    it "should not have a path" do
      @grid_fs_file.path.should be_nil
    end
    
    it "should not have a URL" do
      @grid_fs_file.url.should be_nil
    end
    
    it "should be deletable" do
      @grid_fs_file.delete
      GridFS::GridStore.read(@database, 'uploads/bar.txt').should == ''
    end
    
    it "should store the content type on GridFS" do
      @grid_fs_file.content_type.should == 'application/xml'
    end
  end
  
  describe '#retrieve!' do
    before do
      GridFS::GridStore.open(@database, 'uploads/bar.txt', 'w') { |f| f.puts "A test, 1234" }
      @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')
      @grid_fs_file = @storage.retrieve!('bar.txt')
    end

    it "should retrieve the file contents from gridfs" do
      @grid_fs_file.read.chomp.should == "A test, 1234"
    end
    
    it "should not have a path" do
      @grid_fs_file.path.should be_nil
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
      GridFS::GridStore.read(@database, 'uploads/bar.txt').should == ''
    end
  end

end
