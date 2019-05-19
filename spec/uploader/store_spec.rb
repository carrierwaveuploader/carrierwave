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
      expect(@uploader.store_dir).to eq('uploads')
    end
  end

  describe '#filename' do
    it "should default to nil" do
      expect(@uploader.filename).to be_nil
    end
  end

  describe '#store!' do
    before do
      @file = File.open(file_path('test.jpg'))

      allow(CarrierWave).to receive(:generate_cache_id).and_return('1390890634-26112-1234-2122')

      @cached_file = double('a cached file')
      allow(@cached_file).to receive(:delete)

      @stored_file = double('a stored file')
      allow(@stored_file).to receive(:path).and_return('/path/to/somewhere')
      allow(@stored_file).to receive(:url).and_return('http://www.example.com')

      @storage = double('a storage engine')
      allow(@storage).to receive(:cache!).and_return(@cached_file)
      allow(@storage).to receive(:retrieve_from_cache!).and_return(@cached_file)
      allow(@storage).to receive(:store!).and_return(@stored_file)
      allow(@storage).to receive(:identifier).and_return('this-is-me')
      allow(@storage).to receive(:delete_dir!).with("uploads/tmp/#{CarrierWave.generate_cache_id}")

      allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
    end

    it "should set the current path" do
      @uploader.store!(@file)
      expect(@uploader.current_path).to eq('/path/to/somewhere')
    end

    it "should not be cached" do
      @uploader.store!(@file)
      expect(@uploader).not_to be_cached
    end

    it "should set the url" do
      @uploader.store!(@file)
      expect(@uploader.url).to eq('http://www.example.com')
    end

    it "should set the identifier" do
      @uploader.store!(@file)
      expect(@uploader.identifier).to eq('this-is-me')
    end

    it "should clear the retrieved identifier when new file is stored" do
      allow(@storage).to receive(:retrieve!).and_return(@stored_file)
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.store!(@file)
      expect(@uploader.identifier).to eq('this-is-me')
    end

    it "should, if a file is given as argument, cache that file" do
      expect(@uploader).to receive(:cache!).with(@file)
      @uploader.store!(@file)
    end

    it "should use a previously cached file if no argument is given" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader).not_to receive(:cache!)
      @uploader.store!
    end

    it "should instruct the storage engine to store the file" do
      @uploader.cache!(@file)
      expect(@storage).to receive(:store!).with(@uploader.file).and_return(:monkey)
      @uploader.store!
    end

    it "should reset the cache_name" do
      @uploader.cache!(@file)
      @uploader.store!
      expect(@uploader.cache_name).to be_nil
    end

    it "should cache the result given by the storage engine" do
      @uploader.store!(@file)
      expect(@uploader.file).to eq(@stored_file)
    end

    it "should delete the old file" do
      @uploader.cache!(@file)
      expect(@uploader.file).to receive(:delete).and_return(true)
      @uploader.store!
    end

    context "with the cache_only option set to true" do
      before do
        @uploader_class.cache_only = true
      end

      it "should not instruct the storage engine to store the file" do
        @uploader.cache!(@file)
        expect(@storage).not_to receive(:store!)
        @uploader.store!
      end

      it "should still be cached" do
        @uploader.store!(@file)
        expect(@uploader).to be_cached
      end

      it "should not reset the cache_name" do
        @uploader.cache!(@file)
        @uploader.store!
        expect(@uploader.cache_name).not_to be_nil
      end

      it "should not delete the old file" do
        @uploader.cache!(@file)
        expect(@uploader.file).not_to receive(:delete)
        @uploader.store!
      end
    end

    context "with the delete_tmp_file_after_storage option set to false" do
      before do
        @uploader_class.delete_tmp_file_after_storage = false
      end

      it "should not delete the old file" do
        @uploader.cache!(@file)
        expect(@uploader.file).not_to receive(:delete)
        @uploader.store!
      end

      it "should not delete the old cache_id" do
        @uploader.cache!(@file)

        expect(@storage).not_to receive(:delete_dir!)
        @uploader.store!
      end
    end

    it "should delete the old cache_id" do
      @uploader.cache!(@file)

      expect(@storage).to receive(:delete_dir!)
      @uploader.store!
    end

    it "should do nothing when trying to store an empty file" do
      @uploader.store!(nil)
    end

    it "should not re-store a retrieved file" do
      @stored_file = double('a stored file')
      allow(@storage).to receive(:retrieve!).and_return(@stored_file)

      expect(@uploader_class.storage).not_to receive(:store!)
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.store!
    end
  end

  describe '#retrieve_from_store!' do
    before do
      @cached_file = double('a cached file')
      allow(@cached_file).to receive(:delete)

      @stored_file = double('a stored file')
      allow(@stored_file).to receive(:path).and_return('/path/to/somewhere')
      allow(@stored_file).to receive(:url).and_return('http://www.example.com')

      @storage = double('a storage engine')
      allow(@storage).to receive(:retrieve_from_cache!).and_return(@cached_file)
      allow(@storage).to receive(:retrieve!).and_return(@stored_file)
      allow(@storage).to receive(:identifier).and_return('this-is-me')

      allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
    end

    it "should set the current path" do
      @uploader.retrieve_from_store!('monkey.txt')
      expect(@uploader.current_path).to eq('/path/to/somewhere')
    end

    it "should not be cached" do
      @uploader.retrieve_from_store!('monkey.txt')
      expect(@uploader).not_to be_cached
    end

    it "should set the url" do
      @uploader.retrieve_from_store!('monkey.txt')
      expect(@uploader.url).to eq('http://www.example.com')
    end

    it "should set the identifier" do
      @uploader.retrieve_from_store!('monkey.txt')
      expect(@uploader.identifier).to eq('monkey.txt')
    end

    it "should instruct the storage engine to retrieve the file and store the result" do
      expect(@storage).to receive(:retrieve!).with('monkey.txt').and_return(@stored_file)
      @uploader.retrieve_from_store!('monkey.txt')
      expect(@uploader.file).to eq(@stored_file)
    end

    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('1369894322-345-1234-2255/test.jpeg')
      @uploader.retrieve_from_store!('bork.txt')
      expect(@uploader.file).to eq(@stored_file)
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
      expect(File.exist?(@path)).to be_truthy
    end

    it "should not create new files if there is no file" do
      @uploader.store!(nil)
      @path = ::File.expand_path(@uploader.store_path, @uploader.root)
      expect(File.exist?(@path)).to be_falsey
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
      expect(File.exist?(@path)).to be_truthy
      expect(@uploader.url).to eq('/test.jpg')
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

        allow(CarrierWave).to receive(:generate_cache_id).and_return('1390890634-26112-1234-2122')

        @cached_file = double('a cached file')
        allow(@cached_file).to receive(:delete)

        @stored_file = double('a stored file')
        allow(@stored_file).to receive(:path).and_return('/path/to/somewhere')
        allow(@stored_file).to receive(:url).and_return('http://www.example.com')

        @storage = double('a storage engine')
        allow(@storage).to receive(:cache!).and_return(@cached_file)
        allow(@storage).to receive(:store!).and_return(@stored_file)
        allow(@storage).to receive(:delete_dir!).with("uploads/tmp/#{CarrierWave.generate_cache_id}")

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
      end

      it "should set the current path" do
        @uploader.store!(@file)
        expect(@uploader.current_path).to eq('/path/to/somewhere')
      end

      it "should set the url" do
        @uploader.store!(@file)
        expect(@uploader.url).to eq('http://www.example.com')
      end

      it "should, if a file is given as argument, reverse the filename" do
        @uploader.store!(@file)
        expect(@uploader.filename).to eq('gpj.tset')
      end

    end

    describe '#retrieve_from_store!' do
      before do
        @stored_file = double('a stored file')
        allow(@stored_file).to receive(:path).and_return('/path/to/somewhere')
        allow(@stored_file).to receive(:url).and_return('http://www.example.com')

        @storage = double('a storage engine')
        allow(@storage).to receive(:retrieve!).and_return(@stored_file)

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
      end

      it "should set the current path" do
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.current_path).to eq('/path/to/somewhere')
      end

      it "should set the url" do
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.url).to eq('http://www.example.com')
      end

      it "should pass the identifier to the storage engine" do
        expect(@storage).to receive(:retrieve!).with('monkey.txt').and_return(@stored_file)
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.file).to eq(@stored_file)
      end

      it "should not set the filename" do
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.filename).to be_nil
      end
    end

  end

  describe "#store! with the move_to_store option" do

    before do
      @file = File.open(file_path('test.jpg'))
      @uploader_class.permissions = 0777
      @uploader_class.directory_permissions = 0777
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    context "set to true" do
      before do
        @uploader_class.move_to_store = true
      end

      it "should move it from the tmp dir to the store dir" do
        @uploader.cache!(@file)

        @cached_path = @uploader.file.path
        @stored_path = ::File.expand_path(@uploader.store_path, @uploader.root)

        expect(@cached_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/test.jpg'))
        expect(File.exist?(@cached_path)).to be_truthy
        expect(File.exist?(@stored_path)).to be_falsey

        @uploader.store!

        expect(File.exist?(@cached_path)).to be_falsey
        expect(File.exist?(@stored_path)).to be_truthy
      end

      it "should use move_to() during store!()" do
        @uploader.cache!(@file)
        @stored_path = ::File.expand_path(@uploader.store_path, @uploader.root)

        expect(@uploader.file).to receive(:move_to).with(@stored_path, 0777, 0777)
        expect(@uploader.file).not_to receive(:copy_to)

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

        expect(@uploader.file).to receive(:copy_to).with(@stored_path, 0777, 0777)
        expect(@uploader.file).not_to receive(:move_to)

        @uploader.store!
      end
    end
  end

end
