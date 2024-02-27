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

  context "with a filename safeguarded by 'if original_filename'" do
    before do
      @uploader_class.class_eval do
        def filename
          "foo.jpg" if original_filename
        end
      end
    end

    it "shows warning on store only once" do
      expect(@uploader).to receive(:warn).with(/Your uploader's #filename method .+ didn't return value/).once
      @file = File.open(file_path('test.jpg'))
      @uploader.store!(@file)
      @file = File.open(file_path('bork.txt'))
      @uploader.store!(@file)
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
        allow(@storage).to receive(:identifier).and_return(@uploader.deduplicated_filename)

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
      @uploader_class.permissions = 0o777
      @uploader_class.directory_permissions = 0o777
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

        expect(@uploader.file).to receive(:move_to).with(@stored_path, 0o777, 0o777)
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

        expect(@uploader.file).to receive(:copy_to).with(@stored_path, 0o777, 0o777)
        expect(@uploader.file).not_to receive(:move_to)

        @uploader.store!
      end
    end
  end

  describe "#deduplicate" do
    let(:file) { stub_file('test.jpg') }

    before do
      allow(CarrierWave::SanitizedFile).to receive(:sanitize_regexp).and_return(/[^A-z0-9\.\(\)]/)

      @uploader.cache!(file)
    end

    it "tries to find a non-duplicate filename" do
      @uploader.deduplicate(['test.jpg'])
      expect(@uploader.deduplicated_filename).to eq('test(2).jpg')
    end

    it "does nothing when filename doesn't collide" do
      @uploader.deduplicate(['file.jpg'])
      expect(@uploader.deduplicated_filename).to eq('test.jpg')
    end

    it "chooses the first non-colliding name" do
      @uploader.deduplicate(['test.jpg', 'test(2).jpg', 'test(4).jpg'])
      expect(@uploader.deduplicated_filename).to eq('test(3).jpg')
    end

    it "resets the deduplication index value from the previous attempt" do
      @uploader.deduplicate(['test.jpg'])
      @uploader.deduplicate(['test.png'])
      expect(@uploader.deduplicated_filename).to eq('test.jpg')
    end

    context "when deduplication is unnecessary" do
      let(:file) { stub_tempfile('test.jpg', nil, 'test(2).jpg') }

      it "does not change the suffix" do
        @uploader.deduplicate([])
        expect(@uploader.deduplicated_filename).to eq('test(2).jpg')
      end
    end
  end

  describe "#deduplicated_filename" do
    subject { @uploader.deduplicated_filename }

    it "returns the filename when deduplication index is not set" do
      allow(@uploader).to receive(:filename).and_return('filename.jpg')
      is_expected.to eq('filename.jpg')
    end

    it "returns the filename with its suffix unchanged when deduplication index is not set" do
      allow(@uploader).to receive(:filename).and_return('filename(2).jpg')
      is_expected.to eq('filename(2).jpg')
    end

    it "returns the filename without appending the suffix when deduplication index is 1" do
      allow(@uploader).to receive(:filename).and_return('filename(2).jpg')
      @uploader.instance_variable_set :@deduplication_index, 1
      is_expected.to eq('filename.jpg')
    end

    it "appends the deduplication index as suffix" do
      allow(@uploader).to receive(:filename).and_return('filename.jpg')
      @uploader.instance_variable_set :@deduplication_index, 5
      is_expected.to eq('filename(5).jpg')
    end

    it "reuses the parentheses" do
      allow(@uploader).to receive(:filename).and_return('filename(42).jpg')
      @uploader.instance_variable_set :@deduplication_index, 269
      is_expected.to eq('filename(269).jpg')
    end

    it "reuses the parentheses when there's a space before that" do
      allow(@uploader).to receive(:filename).and_return('filename (1).jpg')
      @uploader.instance_variable_set :@deduplication_index, 2
      is_expected.to eq('filename(2).jpg')
    end

    it "does not reuse the parentheses when non-numbers are enclosed" do
      allow(@uploader).to receive(:filename).and_return('filename(A).jpg')
      @uploader.instance_variable_set :@deduplication_index, 2
      is_expected.to eq('filename(A)(2).jpg')
    end
  end
end
