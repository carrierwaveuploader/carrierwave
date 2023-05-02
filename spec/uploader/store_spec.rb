# encoding: utf-8

require 'spec_helper'

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

    it "should delete the old file" do
      @uploader.cache!(@file)
      @uploader.file.should_receive(:delete).and_return(true)
      @uploader.store!
    end

    context "with the delete_tmp_file_after_storage option set to false" do
      before do
        @uploader_class.delete_tmp_file_after_storage = false
      end

      it "should not delete the old file" do
        @uploader.cache!(@file)
        @uploader.file.should_not_receive(:delete)
        @uploader.store!
      end

      it "should not delete the old cache_id" do
        @uploader.cache!(@file)
        cache_path = @uploader.send(:cache_path) # WARNING: violating private
        cache_id_dir = File.dirname(cache_path)
        cache_parent_dir = File.split(cache_id_dir).first
        File.should be_directory(cache_parent_dir)
        File.should be_directory(cache_id_dir)

        @uploader.store!

        File.should be_directory(cache_parent_dir)
        File.should be_directory(cache_id_dir)
      end
    end

    it "should delete the old cache_id" do
      @uploader.cache!(@file)
      cache_path = @uploader.send(:cache_path) # WARNING: violating private
      cache_id_dir = File.dirname(cache_path)
      cache_parent_dir = File.split(cache_id_dir).first
      File.should be_directory(cache_parent_dir)
      File.should be_directory(cache_id_dir)

      @uploader.store!

      File.should be_directory(cache_parent_dir)
      File.should_not be_directory(cache_id_dir)
    end

    context "when the old cache_id directory is not empty" do
      before do
        @uploader.cache!(@file)
        cache_path = @uploader.send(:cache_path) # WARNING: violating private
        @cache_id_dir = File.dirname(cache_path)
        @existing_file = File.join(@cache_id_dir, "exsting_file.txt")
        File.open(@existing_file, "wb"){|f| f << "I exist"}
      end

      it "should not delete the old cache_id" do
        @uploader.store!
        File.should be_directory(@cache_id_dir)
      end

      it "should not delete other existing files in old cache_id dir" do
        @uploader.store!
        File.should exist @existing_file
      end
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
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
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

  describe "#store! with the move_to_store option" do

    before do
      @file = File.open(file_path('test.jpg'))
      @uploader_class.permissions = 0777
      @uploader_class.directory_permissions = 0777
      CarrierWave.stub!(:generate_cache_id).and_return('1369894322-345-2255')
    end

    context "set to true" do
      before do
        @uploader_class.move_to_store = true
      end

      it "should move it from the tmp dir to the store dir" do
        @uploader.cache!(@file)

        @cached_path = @uploader.file.path
        @stored_path = ::File.expand_path(@uploader.store_path, @uploader.root)

        @cached_path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpg')
        File.exist?(@cached_path).should be_true
        File.exist?(@stored_path).should be_false

        @uploader.store!

        File.exist?(@cached_path).should be_false
        File.exist?(@stored_path).should be_true
      end

      it "should use move_to() during store!()" do
        @uploader.cache!(@file)
        @stored_path = ::File.expand_path(@uploader.store_path, @uploader.root)

        @uploader.file.should_receive(:move_to).with(@stored_path, 0777, 0777)
        @uploader.file.should_not_receive(:copy_to)

        @uploader.store!
      end
    end

    context "set to false" do
      before do
        @uploader_class.move_to_store = false
      end

      it "should use copy_to() during store!()" do
        @uploader.cache!(@file)
        @stored_path = ::File.expand_path(@uploader.store_path, @uploader.root)

        @uploader.file.should_receive(:copy_to).with(@stored_path, 0777, 0777)
        @uploader.file.should_not_receive(:move_to)

        @uploader.store!
      end
    end
  end

end
