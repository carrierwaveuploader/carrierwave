require 'spec_helper'

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
      expect(@uploader_class.versions[:thumb]).to be_a(Class)
      expect(@uploader_class.versions[:thumb].ancestors).to include(@uploader_class)
    end

    it "should only assign versions to parent" do
      @uploader_class.version :large
      @uploader_class.version :thumb do
        version :mini do
          version :micro
        end
      end
      expect(@uploader_class.versions.size).to eq(2)
      expect(@uploader_class.versions).to include :large
      expect(@uploader_class.versions).to include :thumb
      expect(@uploader.large.versions).to be_empty
      expect(@uploader.thumb.versions.keys).to eq([:mini])
      expect(@uploader.thumb.mini.versions.keys).to eq([:micro])
      expect(@uploader.thumb.mini.micro.versions).to be_empty
    end

    it "should add an accessor which returns the version" do
      @uploader_class.version :thumb
      expect(@uploader.thumb).to be_a(@uploader_class)
    end

    it "should add it to #versions which returns the version" do
      @uploader_class.version :thumb
      expect(@uploader.versions[:thumb]).to be_a(@uploader_class)
    end

    it "should set the version name" do
      @uploader_class.version :thumb
      expect(@uploader.version_name).to eq(nil)
      expect(@uploader.thumb.version_name).to eq(:thumb)
    end

    it "should set the version names on the class" do
      @uploader_class.version :thumb
      expect(@uploader.class.version_names).to eq([])
      expect(@uploader.thumb.class.version_names).to eq([:thumb])
    end

    it "should remember mount options" do
      model = double('a model')
      @uploader_class.version :thumb
      @uploader = @uploader_class.new(model, :gazelle)

      expect(@uploader.thumb.model).to eq(model)
      expect(@uploader.thumb.mounted_as).to eq(:gazelle)
    end

    it "should apply any overrides given in a block" do
      @uploader_class.version :thumb do
        def store_dir
          public_path('monkey/apache')
        end
      end
      expect(@uploader.store_dir).to eq('uploads')
      expect(@uploader.thumb.store_dir).to eq(public_path('monkey/apache'))
    end

    it "should not initially have a value for enable processing" do
      thumb = (@uploader_class.version :thumb)
      expect(thumb.instance_variable_get('@enable_processing')).to be_nil
    end

    it "should return the enable processing value of the parent" do
      @uploader_class.enable_processing = false
      thumb = (@uploader_class.version :thumb)
      expect(thumb.enable_processing).to be_falsey
    end

    it "should return its own value for enable processing if set" do
      @uploader_class.enable_processing = false
      thumb = @uploader_class.version :thumb
      thumb.enable_processing = true
      expect(thumb.enable_processing).to be_truthy
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
      expect(@uploader_class.version(:thumb).monkey).to eq("monkey")
      expect(@uploader_class.version(:thumb).llama).to eq("llama")
    end

    it "should reopen the same instance when called multiple times" do
      @uploader_class.version :thumb do
        def store_dir
          public_path('monkey/apache')
        end
      end
      @uploader_class.version :thumb do
        def store_dir
          public_path('monkey/apache/new')
        end
      end

      expect(@uploader.thumb.store_dir).to eq(public_path('monkey/apache/new'))
    end

    it "should accept option :from_version" do
      @uploader_class.version :small_thumb, :from_version => :thumb
      expect(@uploader_class.version(:small_thumb).version_options[:from_version]).to eq(:thumb)
    end

    describe 'with nested versions' do
      before do
        @uploader_class.version :thumb do
          version :mini
          version :micro
        end
      end

      it "should add an array of version names" do
        expect(@uploader.class.version_names).to eq([])
        expect(@uploader.thumb.class.version_names).to eq([:thumb])
        expect(@uploader.thumb.mini.class.version_names).to eq([:thumb, :mini])
        expect(@uploader.thumb.micro.class.version_names).to eq([:thumb, :micro])
      end

      it "should set the version name for the instances" do
        expect(@uploader.version_name).to be_nil
        expect(@uploader.thumb.version_name).to eq(:thumb)
        expect(@uploader.thumb.mini.version_name).to eq(:thumb_mini)
        expect(@uploader.thumb.micro.version_name).to eq(:thumb_micro)
      end

      it "should set the version name for the #versions" do
        expect(@uploader.version_name).to be_nil
        expect(@uploader.versions[:thumb].version_name).to eq(:thumb)
        expect(@uploader.versions[:thumb].versions[:mini].version_name).to eq(:thumb_mini)
        expect(@uploader.versions[:thumb].versions[:micro].version_name).to eq(:thumb_micro)
      end

      it "should process nested versions" do
        @uploader_class.class_eval {
          include CarrierWave::MiniMagick

          version :rotated do
            process :rotate

            version :boxed do
              process :resize_to_fit => [200, 200]
            end
          end

          def rotate
            manipulate! do |img|
              img.rotate "90"
              img
            end
          end
        }
        @uploader.cache! File.open(file_path('portrait.jpg'))

        expect(@uploader).to have_dimensions(233, 337)
        expect(@uploader.rotated).to have_dimensions(337, 233)
        expect(@uploader.rotated.boxed).to have_dimensions(200, 138)
      end
    end

    describe 'with inheritance' do

      before do
        @uploader_class.version :thumb do
          def store_dir
            public_path('monkey/apache')
          end
        end

        @child_uploader_class = Class.new(@uploader_class)
        @child_uploader = @child_uploader_class.new
      end

      it "should override parent version" do
        @child_uploader_class.version :thumb do
          def store_dir
            public_path('monkey/apache/child')
          end
        end

        expect(@child_uploader.thumb.store_dir).to eq(public_path('monkey/apache/child'))
      end

      it "shouldn't affect parent class' version" do
        @child_uploader_class.version :thumb do
          def store_dir
            public_path('monkey/apache/child')
          end
        end

        expect(@uploader.thumb.store_dir).to eq(public_path('monkey/apache'))
      end
    end
  end

  describe 'with a version' do
    before do
      @uploader_class.version(:thumb)
    end

    describe '#cache!' do

      before do
        allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
      end

      it "should set store_path with versions" do
        expect(CarrierWave).to receive(:generate_cache_id).once
        @uploader.cache!(File.open(file_path('test.jpg')))
        expect(@uploader.store_path).to eq('uploads/test.jpg')
        expect(@uploader.thumb.store_path).to eq('uploads/thumb_test.jpg')
        expect(@uploader.thumb.store_path('kebab.png')).to eq('uploads/thumb_kebab.png')
      end

      it "should move it to the tmp dir with the filename prefixed" do
        expect(CarrierWave).to receive(:generate_cache_id).once
        @uploader.cache!(File.open(file_path('test.jpg')))
        expect(@uploader.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/test.jpg'))
        expect(@uploader.thumb.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg'))
        expect(@uploader.file.exists?).to be_truthy
        expect(@uploader.thumb.file.exists?).to be_truthy
      end

      it "should cache the files based on the parent" do
        expect(CarrierWave).to receive(:generate_cache_id).once
        @uploader.cache!(File.open(file_path('bork.txt')))

        expect(File.read(public_path(@uploader.to_s))).to eq(File.read(public_path(@uploader.thumb.to_s)))
      end
    end

    describe "version with move_to_cache set" do
      before do
        FileUtils.cp(file_path('test.jpg'), file_path('test_copy.jpg'))
        allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
        @uploader_class.send(:define_method, :move_to_cache) do
          true
        end
      end

      after do
        FileUtils.mv(file_path('test_copy.jpg'), file_path('test.jpg'))
      end

      it "should copy the parent file when creating the version" do
        @uploader_class.version(:thumb)
        @uploader.cache!(File.open(file_path('test.jpg')))
        expect(@uploader.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/test.jpg'))
        expect(@uploader.thumb.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg'))
        expect(@uploader.file.exists?).to be_truthy
        expect(@uploader.thumb.file.exists?).to be_truthy
      end

      it "should allow overriding move_to_cache on versions" do
        @uploader_class.version(:thumb) do
          def move_to_cache
            true
          end
        end
        @uploader.cache!(File.open(file_path('test.jpg')))
        expect(@uploader.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/test.jpg'))
        expect(@uploader.thumb.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg'))
        expect(@uploader.file.exists?).to be_falsey
        expect(@uploader.thumb.file.exists?).to be_truthy
      end
    end

    describe '#retrieve_from_cache!' do
      it "should set the path to the tmp dir" do
        @uploader.retrieve_from_cache!('1369894322-345-1234-2255/test.jpg')
        expect(@uploader.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/test.jpg'))
        expect(@uploader.thumb.current_path).to eq(public_path('uploads/tmp/1369894322-345-1234-2255/thumb_test.jpg'))
      end

      it "should set store_path with versions" do
        @uploader.retrieve_from_cache!('1369894322-345-1234-2255/test.jpg')
        expect(@uploader.store_path).to eq('uploads/test.jpg')
        expect(@uploader.thumb.store_path).to eq('uploads/thumb_test.jpg')
        expect(@uploader.thumb.store_path('kebab.png')).to eq('uploads/thumb_kebab.png')
      end
    end

    describe '#store!' do
      before do
        @uploader_class.storage = mock_storage('base')
        @uploader_class.version(:thumb).storage = mock_storage('thumb')
        @uploader_class.version(:preview).storage = mock_storage('preview')

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = double('a stored file')
        allow(@base_stored_file).to receive(:path).and_return('/path/to/somewhere')
        allow(@base_stored_file).to receive(:url).and_return('http://www.example.com')

        @thumb_stored_file = double('a thumb version of a stored file')
        allow(@thumb_stored_file).to receive(:path).and_return('/path/to/somewhere/thumb')
        allow(@thumb_stored_file).to receive(:url).and_return('http://www.example.com/thumb')

        @preview_stored_file = double('a preview version of a stored file')
        allow(@preview_stored_file).to receive(:path).and_return('/path/to/somewhere/preview')
        allow(@preview_stored_file).to receive(:url).and_return('http://www.example.com/preview')

        @storage = double('a storage engine')
        allow(@storage).to receive(:store!).and_return(@base_stored_file)

        @thumb_storage = double('a storage engine for thumbnails')
        allow(@thumb_storage).to receive(:store!).and_return(@thumb_stored_file)

        @preview_storage = double('a storage engine for previews')
        allow(@preview_storage).to receive(:store!).and_return(@preview_stored_file)

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
        allow(@uploader_class.version(:thumb).storage).to receive(:new).and_return(@thumb_storage)
        allow(@uploader_class.version(:preview).storage).to receive(:new).and_return(@preview_storage)
      end

      it "should set the current path for the version" do
        @uploader.store!(@file)
        expect(@uploader.current_path).to eq('/path/to/somewhere')
        expect(@uploader.thumb.current_path).to eq('/path/to/somewhere/thumb')
      end

      it "should set the url" do
        @uploader.store!(@file)
        expect(@uploader.url).to eq('http://www.example.com')
        expect(@uploader.thumb.url).to eq('http://www.example.com/thumb')
      end

      it "should, if a file is given as argument, set the store_path" do
        @uploader.store!(@file)
        expect(@uploader.store_path).to eq('uploads/test.jpg')
        expect(@uploader.thumb.store_path).to eq('uploads/thumb_test.jpg')
        expect(@uploader.thumb.store_path('kebab.png')).to eq('uploads/thumb_kebab.png')
      end

      it "should instruct the storage engine to store the file and its version" do
        @uploader.cache!(@file)
        expect(@storage).to receive(:store!).with(@uploader.file).and_return(:monkey)
        expect(@thumb_storage).to receive(:store!).with(@uploader.thumb.file).and_return(:gorilla)
        @uploader.store!
      end

      it "should process conditional versions if the condition method returns true" do
        @uploader_class.version(:preview).version_options[:if] = :true?
        expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
        @uploader.store!(@file)
        expect(@uploader.thumb).to be_present
        expect(@uploader.preview).to be_present
      end

      it "should not process conditional versions if the condition method returns false" do
        @uploader_class.version(:preview).version_options[:if] = :false?
        expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
        @uploader.store!(@file)
        expect(@uploader.thumb).to be_present
        expect(@uploader.preview).to be_blank
      end

      it "should process conditional version if the condition block returns true" do
        @uploader_class.version(:preview).version_options[:if] = lambda{|record, args| record.true?(args[:file])}
        expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
        @uploader.store!(@file)
        expect(@uploader.thumb).to be_present
        expect(@uploader.preview).to be_present
      end

      it "should not process conditional versions if the condition block returns false" do
        @uploader_class.version(:preview).version_options[:if] = lambda{|record, args| record.false?(args[:file])}
        expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
        @uploader.store!(@file)
        expect(@uploader.thumb).to be_present
        expect(@uploader.preview).to be_blank
      end

      it "should not cache file twice when store! called with a file" do
        @uploader_class.process :banana
        @uploader.thumb.class.process :banana

        expect(@uploader).to receive(:banana).at_least(:once).at_most(:once).and_return(true)
        expect(@uploader.thumb).to receive(:banana).at_least(:once).at_most(:once).and_return(true)

        @uploader.store!(@file)
        expect(@uploader.store_path).to eq('uploads/test.jpg')
        expect(@uploader.thumb.store_path).to eq('uploads/thumb_test.jpg')
      end
    end

    describe '#recreate_versions!' do
      before do
        @file = File.open(file_path('test.jpg'))
      end

      it "should overwrite all stored versions with the contents of the original file" do
        @uploader.store!(@file)

        File.open(@uploader.path, 'w') { |f| f.write "Contents changed" }
        expect(File.read(@uploader.thumb.path)).not_to eq("Contents changed")
        @uploader.recreate_versions!
        expect(File.read(@uploader.thumb.path)).to eq("Contents changed")
      end

      it "should keep the original file" do
        @uploader.store!(@file)

        expect(File.read(@uploader.path)).not_to eq("Contents changed")
        File.open(@uploader.path, 'w') { |f| f.write "Contents changed" }
        @uploader.recreate_versions!
        expect(File.read(@uploader.path)).to eq("Contents changed")
      end

      it "should recreate all versions if any are missing" do
        @uploader.store!(@file)

        expect(File.exist?(@uploader.thumb.path)).to eq(true)
        FileUtils.rm(@uploader.thumb.path)
        expect(File.exist?(@uploader.thumb.path)).to eq(false)

        @uploader.recreate_versions!

        expect(File.exist?(@uploader.thumb.path)).to eq(true)
      end

      it "should recreate only specified versions if passed as args" do
        @uploader_class.version(:mini)
        @uploader_class.version(:maxi)
        @uploader.store!(@file)

        expect(File.exist?(@uploader.thumb.path)).to eq(true)
        expect(File.exist?(@uploader.mini.path)).to eq(true)
        expect(File.exist?(@uploader.maxi.path)).to eq(true)
        FileUtils.rm(@uploader.thumb.path)
        expect(File.exist?(@uploader.thumb.path)).to eq(false)
        FileUtils.rm(@uploader.mini.path)
        expect(File.exist?(@uploader.mini.path)).to eq(false)
        FileUtils.rm(@uploader.maxi.path)
        expect(File.exist?(@uploader.maxi.path)).to eq(false)

        @uploader.recreate_versions!(:thumb, :maxi)

        expect(File.exist?(@uploader.thumb.path)).to eq(true)
        expect(File.exist?(@uploader.maxi.path)).to eq(true)
        expect(File.exist?(@uploader.mini.path)).to eq(false)
      end

      it "should not create version if proc returns false" do
        @uploader_class.version(:mini, :if => Proc.new { |*args| false } )
        @uploader.store!(@file)

        expect(@uploader.mini.path).to be_nil

        @uploader.recreate_versions!(:mini)

        expect(@uploader.mini.path).to be_nil
      end

      it "should not change the case of versions" do
        @file = File.open(file_path('Uppercase.jpg'))
        @uploader.store!(@file)
        expect(@uploader.thumb.path).to eq(public_path('uploads/thumb_Uppercase.jpg'))
        @uploader.recreate_versions!
        expect(@uploader.thumb.path).to eq(public_path('uploads/thumb_Uppercase.jpg'))
      end
    end

    describe '#remove!' do
      before do
        @uploader_class.storage = mock_storage('base')
        @uploader_class.version(:thumb).storage = mock_storage('thumb')

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = double('a stored file')
        @thumb_stored_file = double('a thumb version of a stored file')

        @storage = double('a storage engine')
        allow(@storage).to receive(:store!).and_return(@base_stored_file)

        @thumb_storage = double('a storage engine for thumbnails')
        allow(@thumb_storage).to receive(:store!).and_return(@thumb_stored_file)

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
        allow(@uploader_class.version(:thumb).storage).to receive(:new).with(@uploader.thumb).and_return(@thumb_storage)

        allow(@base_stored_file).to receive(:delete)
        allow(@thumb_stored_file).to receive(:delete)

        @uploader.store!(@file)
      end

      it "should reset the current path for the version" do
        @uploader.remove!
        expect(@uploader.current_path).to be_nil
        expect(@uploader.thumb.current_path).to be_nil
      end

      it "should reset the url" do
        @uploader.remove!
        expect(@uploader.url).to be_nil
        expect(@uploader.thumb.url).to be_nil
      end

      it "should delete all the files" do
        expect(@base_stored_file).to receive(:delete)
        expect(@thumb_stored_file).to receive(:delete)
        @uploader.remove!
      end

    end

    describe '#retrieve_from_store!' do
      before do
        @uploader_class.storage = mock_storage('base')
        @uploader_class.version(:thumb).storage = mock_storage('thumb')
        @uploader_class.version(:preview).storage = mock_storage('preview')

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = double('a stored file')
        allow(@base_stored_file).to receive(:path).and_return('/path/to/somewhere')
        allow(@base_stored_file).to receive(:url).and_return('http://www.example.com')

        @thumb_stored_file = double('a thumb version of a stored file')
        allow(@thumb_stored_file).to receive(:path).and_return('/path/to/somewhere/thumb')
        allow(@thumb_stored_file).to receive(:url).and_return('http://www.example.com/thumb')

        @preview_stored_file = double('a preview version of a stored file')
        allow(@preview_stored_file).to receive(:path).and_return('/path/to/somewhere/preview')
        allow(@preview_stored_file).to receive(:url).and_return('http://www.example.com/preview')

        @storage = double('a storage engine')
        allow(@storage).to receive(:retrieve!).and_return(@base_stored_file)

        @thumb_storage = double('a storage engine for thumbnails')
        allow(@thumb_storage).to receive(:retrieve!).and_return(@thumb_stored_file)

        @preview_storage = double('a storage engine for previewnails')
        allow(@preview_storage).to receive(:retrieve!).and_return(@preview_stored_file)

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
        allow(@uploader_class.version(:thumb).storage).to receive(:new).with(@uploader.thumb).and_return(@thumb_storage)
        allow(@uploader_class.version(:preview).storage).to receive(:new).with(@uploader.preview).and_return(@preview_storage)
      end

      it "should set the current path" do
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.current_path).to eq('/path/to/somewhere')
        expect(@uploader.thumb.current_path).to eq('/path/to/somewhere/thumb')
      end

      it "should set the url" do
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.url).to eq('http://www.example.com')
        expect(@uploader.thumb.url).to eq('http://www.example.com/thumb')
      end

      it "should pass the identifier to the storage engine" do
        expect(@storage).to receive(:retrieve!).with('monkey.txt').and_return(@base_stored_file)
        expect(@thumb_storage).to receive(:retrieve!).with('monkey.txt').and_return(@thumb_stored_file)
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.file).to eq(@base_stored_file)
        expect(@uploader.thumb.file).to eq(@thumb_stored_file)
      end

      it "should not set the filename" do
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.filename).to be_nil
      end

      it "should process conditional versions if the condition method returns true" do
        @uploader_class.version(:preview).version_options[:if] = :true?
        expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.thumb).to be_present
        expect(@uploader.preview).to be_present
      end

      it "should not process conditional versions if the condition method returns false" do
        @uploader_class.version(:preview).version_options[:if] = :false?
        expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
        @uploader.retrieve_from_store!('monkey.txt')
        expect(@uploader.thumb).to be_present
        expect(@uploader.preview).to be_blank
      end
    end
  end

  describe 'with a version with option :from_version' do
    before do
      @uploader_class.class_eval do
        def upcase
          content = File.read(current_path)
          File.open(current_path, 'w') { |f| f.write content.upcase }
        end
      end

      @uploader_class.version(:thumb) do
        process :upcase
      end

      @uploader_class.version(:small_thumb, :from_version => :thumb)
    end

    describe '#cache!' do
      before do
        allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
      end

      it "should cache the files based on the version" do
        @uploader.cache!(File.open(file_path('bork.txt')))

        expect(File.read(public_path(@uploader.to_s))).not_to eq(File.read(public_path(@uploader.thumb.to_s)))
        expect(File.read(public_path(@uploader.thumb.to_s))).to eq(File.read(public_path(@uploader.small_thumb.to_s)))
      end
    end
  end
end
