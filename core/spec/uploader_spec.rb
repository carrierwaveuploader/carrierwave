require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::Uploader do
  
  before do
    @uploader_class = Class.new(Merb::Upload::Uploader)
    @uploader = @uploader_class.new
  end
  
  after do
    FileUtils.rm_rf(public_path)
  end
  
  describe '.process' do
    it "should add a single processor when a symbol is given" do
      @uploader_class.process :sepiatone
      @uploader.should_receive(:sepiatone)
      @uploader.process!
    end
    
    it "should add multiple processors when an array of symbols is given" do
      @uploader_class.process :sepiatone, :desaturate, :invert
      @uploader.should_receive(:sepiatone)
      @uploader.should_receive(:desaturate)
      @uploader.should_receive(:invert)
      @uploader.process!
    end
    
    it "should add a single processor with an argument when a hash is given" do
      @uploader_class.process :format => 'png'
      @uploader.should_receive(:format).with('png')
      @uploader.process!
    end

    it "should add a single processor with several argument when a hash is given" do
      @uploader_class.process :resize => [200, 300]
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.process!
    end
    
    it "should add multiple processors when an hash with multiple keys is given" do
      @uploader_class.process :resize => [200, 300], :format => 'png'
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.should_receive(:format).with('png')
      @uploader.process!
    end
  end
  
  describe ".storage" do
    it "should set the storage if an argument is given" do
      @uploader_class.storage "blah"
      @uploader_class.storage.should == "blah"
    end
    
    it "should default to file" do
      @uploader_class.storage.should == Merb::Upload::Storage::File
    end
    
    it "should set the storage from the configured shortcuts if a symbol is given" do
      @uploader_class.storage :file
      @uploader_class.storage.should == Merb::Upload::Storage::File
    end
  end
  
  describe '#store_dir' do
    it "should default to the config option" do
      @uploader.store_dir.should == Merb.root / 'public' / 'uploads'
    end
  end
  
  describe '#cache_dir' do
    it "should default to the config option" do
      @uploader.cache_dir.should == Merb.root / 'public' / 'uploads' / 'tmp'
    end
  end
  
  describe '#filename' do
    it "should default to nil" do
      @uploader.filename.should be_nil
    end
  end
  
  describe '#model' do
    it "should be remembered from initialization" do
      model = mock('a model object')
      @uploader = @uploader_class.new(model)
      @uploader.model.should == model
    end
  end
  
  describe '#mounted_as' do
    it "should be remembered from initialization" do
      model = mock('a model object')
      @uploader = @uploader_class.new(model, :llama)
      @uploader.model.should == model
      @uploader.mounted_as.should == :llama
    end
  end
  
  describe '#cache!' do
    
    before do
      @uploader.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end
    
    it "should cache a file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should return a cache id" do
      cache_id = @uploader.cache!(File.open(file_path('test.jpg')))
      cache_id.should == '20071201-1234-345-2255'
    end
    
    it "should store the cache id" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.cache_id.should == '20071201-1234-345-2255'
    end
    
    it "should set the filename to the file's sanitized filename" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.filename.should == 'test.jpg'
    end
    
    it "should move it to the tmp dir" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
      @uploader.file.exists?.should be_true
    end
    
    it "should trigger a process!" do
      @uploader.should_receive(:process!)
      @uploader.cache!(File.open(file_path('test.jpg')))
    end
  end
  
  describe '#retrieve_from_cache!' do
    it "should cache a file" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should set the path to the tmp dir" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end
    
    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/bork.txt')
    end

    it "should store the cache_id" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.cache_id.should == '20071201-1234-345-2255'
    end
    
    it "should store the cache_name" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.cache_name.should == '20071201-1234-345-2255/test.jpeg'
    end
    
    it "should store the identifier" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.identifier.should == 'test.jpeg'
    end
    
    it "should store the filename" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.filename.should == 'test.jpeg'
    end
    
    it "should raise an error when the cache_id has an invalid format" do
      running {
        @uploader.retrieve_from_cache!('12345/test.jpeg')
      }.should raise_error(Merb::Upload::InvalidParameter)
      
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.identifier.should be_nil
      @uploader.cache_name.should be_nil
    end
    
    it "should raise an error when the identifier contains invalid characters" do
      running {
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/te/st.jpeg')
      }.should raise_error(Merb::Upload::InvalidParameter)
      running {
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/te??%st.jpeg')
      }.should raise_error(Merb::Upload::InvalidParameter)
      
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.identifier.should be_nil
      @uploader.cache_name.should be_nil
    end
  end
  
  describe '#retrieve_from_cache' do
    it "should cache a file" do
      @uploader.retrieve_from_cache('20071201-1234-345-2255/test.jpeg')
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should not overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_cache('20071201-1234-345-2255/bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end

    it "should do nothing when the cache_id has an invalid format" do
      @uploader.retrieve_from_cache('12345/test.jpeg')
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.identifier.should be_nil
      @uploader.cache_name.should be_nil
    end
    
    it "should do nothing when the filename contains invalid characters" do
      @uploader.retrieve_from_cache('20071201-1234-345-2255/te??%st.jpeg')
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.identifier.should be_nil
      @uploader.cache_name.should be_nil
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
    
    it "should, if a files is given as an argument and use_cache is false, not cache that file" do
      Merb::Plugins.config[:merb_upload][:use_cache] = false
      @uploader.should_not_receive(:cache!)
      @uploader.store!(@file)
      Merb::Plugins.config[:merb_upload][:use_cache] = true
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
      @storage.stub!(:retrieve!).and_return(:monkey)
    end
    
    it "should instruct the storage engine to retrieve the file and store the result" do
      @storage.should_receive(:retrieve!).and_return(:monkey)
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.file.should == :monkey
    end
    
    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_store!('bork.txt')
      @uploader.file.should == :monkey
    end
    
    it "should set the identifier" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.identifier.should == 'monkey.txt'
    end
    
    it "should raise an error if the identifier contains ivalid characters" do
      running {
        @uploader.retrieve_from_store!('mo%#nkey.txt')
      }.should raise_error(Merb::Upload::InvalidParameter)
    end
  end
  
  describe '#retrieve_from_store' do
    before do
      @storage = mock('storage')
      @uploader.stub!(:storage).and_return(@storage)
      @storage.stub!(:retrieve!)
    end
    
    it "should instruct the storage engine to retrieve the file and store the result" do
      @storage.should_receive(:retrieve!).and_return(:monkey)
      @uploader.retrieve_from_store('monkey.txt')
      @uploader.file.should == :monkey
    end
    
    it "should not overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_store('bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end
    
    it "should set the identifier" do
      @uploader.retrieve_from_store('monkey.txt')
      @uploader.identifier.should == 'monkey.txt'
    end
    
    it "should do nothing if the identifier contains ivalid characters" do
      @storage.should_not_receive(:retrieve!)
      @uploader.retrieve_from_store('mo%#nkey.txt')
    end
  end
  
end