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

  describe '.version' do
    it "should add it to .versions" do
      @uploader_class.version :thumb
      @uploader_class.versions[:thumb].should be_a(Class)
      @uploader_class.versions[:thumb].ancestors.should include(@uploader_class)
    end

    it "should add an accessor which returns the version" do
      @uploader_class.version :thumb
      @uploader.thumb.should be_a(@uploader_class)
    end

    it "should add it to #versions which returns the version" do
      @uploader_class.version :thumb
      @uploader.versions[:thumb].should be_a(@uploader_class)
    end

    it "should set the version name" do
      @uploader_class.version :thumb
      @uploader.version_name.should == nil
      @uploader.thumb.version_name.should == :thumb
    end

    it "should set the version names on the class" do
      @uploader_class.version :thumb
      @uploader.class.version_names.should == []
      @uploader.thumb.class.version_names.should == [:thumb]
    end

    it "should remember mount options" do
      model = mock('a model')
      @uploader_class.version :thumb
      @uploader = @uploader_class.new(model, :gazelle)

      @uploader.thumb.model.should == model
      @uploader.thumb.mounted_as.should == :gazelle
    end

    it "should apply any overrides given in a block" do
      @uploader_class.version :thumb do
        def store_dir
          public_path('monkey/apache')
        end
      end
      @uploader.store_dir.should == 'uploads'
      @uploader.thumb.store_dir.should == public_path('monkey/apache')
    end

    it "should reopen the same class when called multiple times" do
      @uploader_class.version :thumb do
        def self.monkey
          "monkey"
        end
      end
      @uploader_class.version :thumb do
        def self.llama
          "llama"
        end
      end
      @uploader_class.version(:thumb).monkey.should == "monkey"
      @uploader_class.version(:thumb).llama.should == "llama"
    end

    describe 'with nested versions' do
      before do
        @uploader_class.version :thumb do
          version :mini
          version :micro
        end
      end

      it "should add an array of version names" do
        @uploader.class.version_names.should == []
        @uploader.thumb.class.version_names.should == [:thumb]
        @uploader.thumb.mini.class.version_names.should == [:thumb, :mini]
        @uploader.thumb.micro.class.version_names.should == [:thumb, :micro]
      end

      it "should set the version name for the instances" do
        @uploader.version_name.should be_nil
        @uploader.thumb.version_name.should == :thumb
        @uploader.thumb.mini.version_name.should == :thumb_mini
        @uploader.thumb.micro.version_name.should == :thumb_micro
      end

    end

  end

  describe 'with a version' do
    before do
      @uploader_class.version(:thumb)
    end

    describe '#cache!' do

      before do
        CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
      end

      it "should set store_path with versions" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.store_path.should == 'uploads/test.jpg'
        @uploader.thumb.store_path.should == 'uploads/thumb_test.jpg'
        @uploader.thumb.store_path('kebab.png').should == 'uploads/thumb_kebab.png'
      end

      it "should move it to the tmp dir with the filename prefixed" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
        @uploader.thumb.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/thumb_test.jpg')
        @uploader.file.exists?.should be_true
        @uploader.thumb.file.exists?.should be_true
      end
    end

    describe '#retrieve_from_cache!' do
      it "should set the path to the tmp dir" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
        @uploader.thumb.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/thumb_test.jpg')
      end

      it "should set store_path with versions" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.store_path.should == 'uploads/test.jpg'
        @uploader.thumb.store_path.should == 'uploads/thumb_test.jpg'
        @uploader.thumb.store_path('kebab.png').should == 'uploads/thumb_kebab.png'
      end
    end

    describe '#store!' do
      before do
        @uploader_class.storage = mock_storage('base')
        @uploader_class.version(:thumb).storage = mock_storage('thumb')

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = mock('a stored file')
        @base_stored_file.stub!(:path).and_return('/path/to/somewhere')
        @base_stored_file.stub!(:url).and_return('http://www.example.com')

        @thumb_stored_file = mock('a thumb version of a stored file')
        @thumb_stored_file.stub!(:path).and_return('/path/to/somewhere/thumb')
        @thumb_stored_file.stub!(:url).and_return('http://www.example.com/thumb')

        @storage = mock('a storage engine')
        @storage.stub!(:store!).and_return(@base_stored_file)

        @thumb_storage = mock('a storage engine for thumbnails')
        @thumb_storage.stub!(:store!).and_return(@thumb_stored_file)

        @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
        @uploader_class.version(:thumb).storage.stub!(:new).with(@uploader.thumb).and_return(@thumb_storage)
      end

      it "should set the current path for the version" do
        @uploader.store!(@file)
        @uploader.current_path.should == '/path/to/somewhere'
        @uploader.thumb.current_path.should == '/path/to/somewhere/thumb'
      end

      it "should set the url" do
        @uploader.store!(@file)
        @uploader.url.should == 'http://www.example.com'
        @uploader.thumb.url.should == 'http://www.example.com/thumb'
      end

      it "should, if a file is given as argument, set the store_path" do
        @uploader.store!(@file)
        @uploader.store_path.should == 'uploads/test.jpg'
        @uploader.thumb.store_path.should == 'uploads/thumb_test.jpg'
        @uploader.thumb.store_path('kebab.png').should == 'uploads/thumb_kebab.png'
      end

      it "should instruct the storage engine to store the file and its version" do
        @uploader.cache!(@file)
        @storage.should_receive(:store!).with(@uploader.file).and_return(:monkey)
        @thumb_storage.should_receive(:store!).with(@uploader.thumb.file).and_return(:gorilla)
        @uploader.store!
      end

    end

    describe '#remove!' do
      before do
        @uploader_class.storage = mock_storage('base')
        @uploader_class.version(:thumb).storage = mock_storage('thumb')

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = mock('a stored file')
        @thumb_stored_file = mock('a thumb version of a stored file')

        @storage = mock('a storage engine')
        @storage.stub!(:store!).and_return(@base_stored_file)

        @thumb_storage = mock('a storage engine for thumbnails')
        @thumb_storage.stub!(:store!).and_return(@thumb_stored_file)

        @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
        @uploader_class.version(:thumb).storage.stub!(:new).with(@uploader.thumb).and_return(@thumb_storage)

        @base_stored_file.stub!(:delete)
        @thumb_stored_file.stub!(:delete)

        @uploader.store!(@file)
      end

      it "should reset the current path for the version" do
        @uploader.remove!
        @uploader.current_path.should be_nil
        @uploader.thumb.current_path.should be_nil
      end

      it "should reset the url" do
        @uploader.remove!
        @uploader.url.should be_nil
        @uploader.thumb.url.should be_nil
      end

      it "should delete all the files" do
        @base_stored_file.should_receive(:delete)
        @thumb_stored_file.should_receive(:delete)
        @uploader.remove!
      end

    end


    describe '#retrieve_from_store!' do
      before do
        @uploader_class.storage = mock_storage('base')
        @uploader_class.version(:thumb).storage = mock_storage('thumb')

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = mock('a stored file')
        @base_stored_file.stub!(:path).and_return('/path/to/somewhere')
        @base_stored_file.stub!(:url).and_return('http://www.example.com')

        @thumb_stored_file = mock('a thumb version of a stored file')
        @thumb_stored_file.stub!(:path).and_return('/path/to/somewhere/thumb')
        @thumb_stored_file.stub!(:url).and_return('http://www.example.com/thumb')

        @storage = mock('a storage engine')
        @storage.stub!(:retrieve!).and_return(@base_stored_file)

        @thumb_storage = mock('a storage engine for thumbnails')
        @thumb_storage.stub!(:retrieve!).and_return(@thumb_stored_file)

        @uploader_class.storage.stub!(:new).with(@uploader).and_return(@storage)
        @uploader_class.version(:thumb).storage.stub!(:new).with(@uploader.thumb).and_return(@thumb_storage)
      end

      it "should set the current path" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.current_path.should == '/path/to/somewhere'
        @uploader.thumb.current_path.should == '/path/to/somewhere/thumb'
      end

      it "should set the url" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.url.should == 'http://www.example.com'
        @uploader.thumb.url.should == 'http://www.example.com/thumb'
      end

      it "should pass the identifier to the storage engine" do
        @storage.should_receive(:retrieve!).with('monkey.txt').and_return(@base_stored_file)
        @thumb_storage.should_receive(:retrieve!).with('monkey.txt').and_return(@thumb_stored_file)
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.file.should == @base_stored_file
        @uploader.thumb.file.should == @thumb_stored_file
      end

      it "should not set the filename" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.filename.should be_nil
      end
    end
  end

end