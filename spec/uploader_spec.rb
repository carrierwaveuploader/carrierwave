require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::Uploader do
  
  before do
    @uploader_class = Class.new(Merb::Upload::Uploader)
    @uploader = @uploader_class.new('something')
  end
  
  after do
    FileUtils.rm_rf(public_path)
  end
  
  describe ".storage" do
    it "should set the storage if an argument is given" do
      @uploader_class.storage "blah"
      @uploader_class.storage.should == "blah"
    end
    
    it "should set the storage from the configured shortcuts if a symbol is given" do
      @uploader_class.storage :file
      @uploader_class.storage.should == Merb::Upload::Storage::File
    end
  end

  describe '#identifier' do
    it "should be remembered" do
      @uploader.identifier.should == 'something'
    end
    
    it "should be changeable" do
      @uploader.identifier = 'anotherthing'
      @uploader.identifier.should == 'anotherthing'
    end
  end
  
  describe '#store_dir' do
    it "should default to the config option" do
      @uploader.store_dir.should == Merb.root / 'public' / 'uploads'
    end
  end
  
  describe '#tmp_dir' do
    it "should default to the config option" do
      @uploader.tmp_dir.should == Merb.root / 'public' / 'uploads' / 'tmp'
    end
  end
  
  describe '#filename' do
    it "should default to the identifier" do
      @uploader.filename.should == 'something'
    end
  end
  
  describe '#cache!' do
    it "should cache a file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should move it to the tmp dir" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.path.should == public_path('uploads/tmp/something')
      @uploader.file.exists?.should be_true
    end
  end
  
  describe '#retrieve_from_cache!' do
    it "should cache a file" do
      @uploader.retrieve_from_cache!
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should set the path to the tmp dir" do
      @uploader.retrieve_from_cache!
      @uploader.file.path.should == public_path('uploads/tmp/something')
    end
  end
  
  describe '#store!' do
    before do
      @storage = mock('storage')
      @uploader.stub!(:storage).and_return(@storage)
      @storage.stub!(:store!).and_return(:monkey)
      @file = File.open(file_path('test.jpg'))
    end
    
    it "should, if a file is given as argument, cache that file" do
      @uploader.should_receive(:cache!).with(@file)
      @uploader.store!(@file)
    end
    
    it "should use a previously cached file if no argument is given" do
      @uploader.should_not_receive(:cache!)
      @uploader.store!
    end
    
    it "should instruct the storage engine to store the file" do
      @uploader.cache!(@file)
      @storage.should_receive(:store!).with(@uploader.file).and_return(:monkey)
      @uploader.store!
    end

    it "should cache the result given by the storage engine" do
      @uploader.store!(@file)
      @uploader.file.should == :monkey
    end
  end
  
  describe '#retrieve_from_store!' do
    before do
      @storage = mock('storage')
      @uploader.stub!(:storage).and_return(@storage)
    end
    
    it "should instruct the storage engine to retrieve the file and store the result" do
      @storage.should_receive(:retrieve!).and_return(:monkey)
      @uploader.retrieve_from_store!
      @uploader.file.should == :monkey
    end
  end
  
end