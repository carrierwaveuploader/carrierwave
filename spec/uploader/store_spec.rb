# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#store_dir' do
    it "should default to the config option" do
      @uploader.store_dir.should == 'uploads'
    end
  end

  describe '#filename' do
    it "should default to nil" do
      @uploader.filename.should be_nil
    end
  end

  describe '#store!' do
    before do
      @file = File.open(file_path('test.jpg'))

      @stored_file = mock('a stored file')
      @stored_file.stub!(:path).and_return('/path/to/somewhere')
      @stored_file.stub!(:url).and_return('http://www.example.com')

      @storage = mock('a storage engine')
      @storage.stub!(:store!).and_return(@stored_file)
      @storage.stub!(:identifier).and_return('this-is-me')

      @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
    end

    it "should set the current path" do
      @uploader.store!(@file)
      @uploader.current_path.should == '/path/to/somewhere'
    end

    it "should not be cached" do
      @uploader.store!(@file)
      @uploader.should_not be_cached
    end

    it "should set the url" do
      @uploader.store!(@file)
      @uploader.url.should == 'http://www.example.com'
    end

    it "should set the identifier" do
      @uploader.store!(@file)
      @uploader.identifier.should == 'this-is-me'
    end

    it "should, if a file is given as argument, cache that file" do
      @uploader.should_receive(:cache!).with(@file)
      @uploader.store!(@file)
    end

    it "should use a previously cached file if no argument is given" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should_not_receive(:cache!)
      @uploader.store!
    end

    it "should instruct the storage engine to store the file" do
      @uploader.cache!(@file)
      @storage.should_receive(:store!).with(@uploader.file).and_return(:monkey)
      @uploader.store!
    end

    it "should reset the cache_name" do
      @uploader.cache!(@file)
      @uploader.store!
      @uploader.cache_name.should be_nil
    end

    it "should cache the result given by the storage engine" do
      @uploader.store!(@file)
      @uploader.file.should == @stored_file
    end

    it "should do nothing when trying to store an empty file" do
      @uploader.store!(nil)
    end

    it "should not re-store a retrieved file" do
      @stored_file = mock('a stored file')
      @storage.stub!(:retrieve!).and_return(@stored_file)

      @uploader_class.storage.should_not_receive(:store!)
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.store!
    end
  end

  describe '#retrieve_from_store!' do
    before do
      @stored_file = mock('a stored file')
      @stored_file.stub!(:path).and_return('/path/to/somewhere')
      @stored_file.stub!(:url).and_return('http://www.example.com')

      @storage = mock('a storage engine')
      @storage.stub!(:retrieve!).and_return(@stored_file)
      @storage.stub!(:identifier).and_return('this-is-me')

      @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
    end

    it "should set the current path" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.current_path.should == '/path/to/somewhere'
    end

    it "should not be cached" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.should_not be_cached
    end

    it "should set the url" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.url.should == 'http://www.example.com'
    end

    it "should set the identifier" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.identifier.should == 'this-is-me'
    end

    it "should instruct the storage engine to retrieve the file and store the result" do
      @storage.should_receive(:retrieve!).with('monkey.txt').and_return(@stored_file)
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.file.should == @stored_file
    end

    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_store!('bork.txt')
      @uploader.file.should == @stored_file
    end
  end
  
  describe 'with an overridden filename' do
    before do
      @uploader_class.class_eval do
        def filename; "foo.jpg"; end
      end
    end

    it "should create new files if there is a file" do
      @file = File.open(file_path('test.jpg'))
      @uploader.store!(@file)
      @path = ::File.expand_path(@uploader.store_path, @uploader.root)
      File.exist?(@path).should be_true
    end
    
    it "should not create new files if there is no file" do
      @uploader.store!(nil)
      @path = ::File.expand_path(@uploader.store_path, @uploader.root)
      File.exist?(@path).should be_false
    end
  end

  describe 'without a store dir' do
    before do
      @uploader_class.class_eval do
        def store_dir; nil; end
      end
    end

    it "should create a new file with a valid path and url" do
      @file = File.open(file_path('test.jpg'))
      @uploader.store!(@file)
      @path = ::File.expand_path(@uploader.store_path, @uploader.root)
      File.exist?(@path).should be_true
      @uploader.url.should == '/test.jpg'
    end
  end

  describe 'with an overridden, reversing, filename' do
    before do
      @uploader_class.class_eval do
        def filename
          super.reverse unless super.blank?
        end
      end
    end

    describe '#store!' do
      before do
        @file = File.open(file_path('test.jpg'))

        @stored_file = mock('a stored file')
        @stored_file.stub!(:path).and_return('/path/to/somewhere')
        @stored_file.stub!(:url).and_return('http://www.example.com')

        @storage = mock('a storage engine')
        @storage.stub!(:store!).and_return(@stored_file)

        @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
      end

      it "should set the current path" do
        @uploader.store!(@file)
        @uploader.current_path.should == '/path/to/somewhere'
      end

      it "should set the url" do
        @uploader.store!(@file)
        @uploader.url.should == 'http://www.example.com'
      end

      it "should, if a file is given as argument, reverse the filename" do
        @uploader.store!(@file)
        @uploader.filename.should == 'gpj.tset'
      end

    end

    describe '#retrieve_from_store!' do
      before do
        @stored_file = mock('a stored file')
        @stored_file.stub!(:path).and_return('/path/to/somewhere')
        @stored_file.stub!(:url).and_return('http://www.example.com')

        @storage = mock('a storage engine')
        @storage.stub!(:retrieve!).and_return(@stored_file)

        @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
      end

      it "should set the current path" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.current_path.should == '/path/to/somewhere'
      end

      it "should set the url" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.url.should == 'http://www.example.com'
      end

      it "should pass the identifier to the storage engine" do
        @storage.should_receive(:retrieve!).with('monkey.txt').and_return(@stored_file)
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.file.should == @stored_file
      end

      it "should not set the filename" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.filename.should be_nil
      end
    end

  end

end