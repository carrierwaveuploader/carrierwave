require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    @uploader_class.constants
      .select { |const| const.to_s =~ /Uploader$/ }
      .each { |const| @uploader_class.send(:remove_const, const)}
    FileUtils.rm_rf(public_path)
  end

  describe '.version' do
    it "should add the builder to .versions" do
      @uploader_class.version :thumb
      expect(@uploader_class.versions[:thumb]).to be_a(CarrierWave::Uploader::Versions::Builder)
    end

    it "should raise an error when a user tries to use a Builder for configuration" do
      @uploader_class.version :thumb
      expect { @uploader_class.versions[:thumb].storage = :file }.to raise_error NoMethodError, /{ self.storage= :file }/
      expect { @uploader_class.versions[:thumb].process convert: :png }.to raise_error NoMethodError, /{ self.process {:?convert(=>|: ):png} }/
    end

    it "should add an version instance to #versions" do
      @uploader_class.version :thumb
      expect(@uploader.versions[:thumb]).to be_a(CarrierWave::Uploader::Base)
      expect(@uploader.versions[:thumb].class.ancestors).to include(@uploader_class)
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

    it "should set the class name" do
      @uploader_class.version :thumb
      expect(@uploader.thumb.class).to eq @uploader_class.const_get :VersionUploaderThumb
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
      @uploader_class.version :thumb
      expect(@uploader.thumb.class.instance_variable_get('@enable_processing')).to be_nil
    end

    it "should return the enable processing value of the parent" do
      @uploader_class.version :thumb
      @uploader_class.enable_processing = false
      expect(@uploader.thumb.class.enable_processing).to be_falsey
    end

    it "should return its own value for enable processing if set" do
      @uploader_class.enable_processing = false
      @uploader_class.version(:thumb) { self.enable_processing = true }
      expect(@uploader.thumb.enable_processing).to be_truthy
    end

    it "should use the enable processing value of the parent after reading its own value" do
      @uploader_class.version :thumb
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader_class.enable_processing = false
      expect(@uploader.thumb.class.enable_processing).to be_falsey
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
      expect(@uploader.thumb.class.monkey).to eq("monkey")
      expect(@uploader.thumb.class.llama).to eq("llama")
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
      expect(@uploader.small_thumb.class.version_options[:from_version]).to eq(:thumb)
    end

    context 'when version name starts with non-alphabetic character' do
      it "should set the class name" do
        @uploader_class.version :_800x600
        expect(@uploader._800x600.class).to eq @uploader_class.const_get :VersionUploader800x600
      end
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
        @uploader_class.class_eval do
          def store_dir
            public_path('monkey')
          end
        end
        @uploader_class.version :thumb do
          def store_dir
            public_path('monkey/apache')
          end
        end
        @uploader_class.version :preview

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

      it "should respect store_dir in the subclass" do
        @child_uploader_class.class_eval do
          def store_dir
            public_path('gorilla')
          end
        end

        expect(@uploader.preview.store_dir).to eq(public_path('monkey'))
        expect(@child_uploader.preview.store_dir).to eq(public_path('gorilla'))
      end

      it "should respect default_url in the subclass" do
        @child_uploader_class.class_eval do
          def default_url
            "/#{version_name}.png"
          end
        end

        expect(@child_uploader.preview.default_url).to eq('/preview.png')
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
        @uploader_class.cache_storage = :file
        @uploader_class.storage = mock_storage('base')
        mock_thumb_storage = mock_storage('thumb')
        @uploader_class.version(:thumb) { self.storage = mock_thumb_storage }
        mock_preview_storage = mock_storage('preview')
        @uploader_class.version(:preview) { self.storage = mock_preview_storage }

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

        @storage = double('a storage instance')
        allow(@storage).to receive(:store!).and_return(@base_stored_file)
        allow(@storage).to receive(:identifier).and_return('test.jpg')

        @thumb_storage = double('a storage instance for thumbnails')
        allow(@thumb_storage).to receive(:store!).and_return(@thumb_stored_file)
        allow(@thumb_storage).to receive(:identifier).and_return('test.jpg')

        @preview_storage = double('a storage instance for previews')
        allow(@preview_storage).to receive(:store!).and_return(@preview_stored_file)
        allow(@preview_storage).to receive(:identifier).and_return('test.jpg')

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
        allow(@uploader.thumb.class.storage).to receive(:new).and_return(@thumb_storage)
        allow(@uploader.preview.class.storage).to receive(:new).and_return(@preview_storage)
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

      context "when there is an 'if' option" do
        it "should process conditional versions if the condition method returns true" do
          @uploader_class.version(:preview, if: :true?)
          expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_present
        end

        it "should not process conditional versions if the condition method returns false" do
          @uploader_class.version(:preview, if: :false?)
          expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_blank
        end

        it "should process conditional version if the condition block returns true" do
          @uploader_class.version(:preview, if: lambda{|record, args| record.true?(args[:file])})
          expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_present
        end

        it "should not process conditional versions if the condition block returns false" do
          @uploader_class.version(:preview, if: lambda{|record, args| record.false?(args[:file])})
          expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_blank
        end
      end

      context "when there is an 'unless' option" do
        it "should not process conditional versions if the condition method returns true" do
          @uploader_class.version(:preview, unless: :true?)
          expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_blank
        end

        it "should process conditional versions if the condition method returns false" do
          @uploader_class.version(:preview, unless: :false?)
          expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_present
        end

        it "should not process conditional version if the condition block returns true" do
          @uploader_class.version(:preview, unless: lambda{|record, args| record.true?(args[:file])})
          expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_blank
        end

        it "should process conditional versions if the condition block returns false" do
          @uploader_class.version(:preview, unless: lambda{|record, args| record.false?(args[:file])})
          expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
          @uploader.store!(@file)
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_present
        end
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

      it "should not process the file multiple times" do
        file_size = @file.read.size
        @uploader_class.class_eval do
          process :shorten

          def shorten
            File.write(file.path, file.read[0...-1])
          end
        end

        @uploader.store!(@file)
        @uploader.recreate_versions!
        expect(@uploader.read.size + 1).to eq(file_size)
        @uploader.recreate_versions!(:thumb)
        expect(@uploader.read.size + 1).to eq(file_size)
      end

      it "should not leave the cache_id set" do
        @uploader.store!(@file)
        @uploader.recreate_versions!
        expect(@uploader).not_to be_cached
      end

      context "when there is an 'if' option" do
        it "should not create version if proc returns false" do
          @uploader_class.version(:mini, :if => Proc.new { |*args| false } )
          @uploader.store!(@file)

          expect(@uploader.mini.path).to be_nil

          @uploader.recreate_versions!(:mini)

          expect(@uploader.mini.path).to be_nil
        end
      end

      context "when there is an 'unless' option" do
        it "should not create version if proc returns true" do
          @uploader_class.version(:mini, :unless => Proc.new { |*args| true } )
          @uploader.store!(@file)

          expect(@uploader.mini.path).to be_nil

          @uploader.recreate_versions!(:mini)

          expect(@uploader.mini.path).to be_nil
        end
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
        @uploader_class.cache_storage = :file
        @uploader_class.storage = mock_storage('base')
        mock_thumb_storage = mock_storage('thumb')
        @uploader_class.version(:thumb) { self.storage = mock_thumb_storage }

        @file = File.open(file_path('test.jpg'))

        @base_stored_file = double('a stored file')
        @thumb_stored_file = double('a thumb version of a stored file')

        @storage = double('a storage engine')
        allow(@storage).to receive(:store!).and_return(@base_stored_file)
        allow(@storage).to receive(:identifier).and_return('test.jpg')

        @thumb_storage = double('a storage engine for thumbnails')
        allow(@thumb_storage).to receive(:store!).and_return(@thumb_stored_file)
        allow(@thumb_storage).to receive(:identifier).and_return('test.jpg')

        allow(@uploader_class.storage).to receive(:new).with(@uploader).and_return(@storage)
        allow(@uploader.thumb.class.storage).to receive(:new).with(@uploader.thumb).and_return(@thumb_storage)

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
        mock_thumb_storage = mock_storage('thumb')
        @uploader_class.version(:thumb) { self.storage = mock_thumb_storage }
        mock_preview_storage = mock_storage('preview')
        @uploader_class.version(:preview) { self.storage = mock_preview_storage }

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
        allow(@uploader.thumb.class.storage).to receive(:new).with(@uploader.thumb).and_return(@thumb_storage)
        allow(@uploader.preview.class.storage).to receive(:new).with(@uploader.preview).and_return(@preview_storage)
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

      context "when there is an 'if' option" do
        it "should process conditional versions if the condition method returns true" do
          @uploader_class.version(:preview, if: :true?)
          expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
          @uploader.retrieve_from_store!('monkey.txt')
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_present
        end

        it "should not process conditional versions if the condition method returns false" do
          @uploader_class.version(:preview, if: :false?)
          expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
          @uploader.retrieve_from_store!('monkey.txt')
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_blank
        end
      end

      context "when there is an 'unless' option" do
        it "should not process conditional versions if the condition method returns true" do
          @uploader_class.version(:preview, unless: :true?)
          expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
          @uploader.retrieve_from_store!('monkey.txt')
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_blank
        end

        it "should process conditional versions if the condition method returns false" do
          @uploader_class.version(:preview, unless: :false?)
          expect(@uploader).to receive(:false?).at_least(:once).and_return(false)
          @uploader.retrieve_from_store!('monkey.txt')
          expect(@uploader.thumb).to be_present
          expect(@uploader.preview).to be_present
        end
      end
    end

    describe '#version_active?' do
      before do
        @file = File.open(file_path('test.jpg'))
        @uploader_class.version(:preview, if: :true?)
      end

      it 'returns true when active' do
        expect(@uploader).to receive(:true?).at_least(:once).and_return(true)
        @uploader.store!(@file)
        expect(@uploader.version_active?(:preview)).to be true
      end

      it 'returns false when inactive' do
        expect(@uploader).to receive(:true?).at_least(:once).and_return(false)
        @uploader.store!(@file)
        expect(@uploader.version_active?(:preview)).to be false
      end
    end

    describe '#version_exists' do
      it 'shows deprecation' do
        expect(CarrierWave.deprecator).to receive(:warn).with(/use version_active\? instead/, any_args)
        @uploader.version_exists?(:preview)
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

      it "should not cache an inactive version" do
        @uploader_class.class_eval do
          def condition(_); false; end
        end
        @uploader_class.version(:conditional_thumb, :from_version => :thumb, :if => :condition)

        @uploader.cache!(File.open(file_path('bork.txt')))
        expect(@uploader.conditional_thumb.cached?).to be false
      end
    end

    describe "#recreate_versions!" do
      let(:bork_file) { File.open(file_path('bork.txt')) }
      let(:original_contents) { File.read(public_path(@uploader.to_s)) }
      let(:thumb_contents) { File.read(public_path(@uploader.thumb.to_s)) }
      let(:small_thumb_contents) { File.read(public_path(@uploader.small_thumb.to_s)) }

      context "when the file is not stored" do
        it "should not break" do
          @uploader.recreate_versions!
          @uploader.recreate_versions!(:small_thumb)
        end
      end

      context "when no versions are given" do
        it "should process file based on the version" do
          @uploader.store!(bork_file)
          @uploader.recreate_versions!
          expect(thumb_contents).to eq(small_thumb_contents)
        end
      end

      context "when version is given" do
        it "should process file based on the version" do
          @uploader.store!(bork_file)
          FileUtils.rm([@uploader.small_thumb.path, @uploader.thumb.path])
          @uploader.recreate_versions!(:small_thumb)
          expect(File.exist?(public_path(@uploader.thumb.to_s))).to be true
          expect(small_thumb_contents).to eq(thumb_contents)
          expect(small_thumb_contents).not_to eq(original_contents)
        end

        it "reprocess parent version, too" do
          @uploader.store!(bork_file)
          FileUtils.rm(@uploader.thumb.path)
          @uploader.recreate_versions!(:small_thumb)
        end

        it "works fine when recreating both dependent and parent versions" do
          @uploader.store!(bork_file)
          FileUtils.rm([@uploader.small_thumb.path, @uploader.thumb.path])
          @uploader.recreate_versions!(:small_thumb, :thumb)
          expect(File.exist?(public_path(@uploader.small_thumb.to_s))).to be true
          expect(File.exist?(public_path(@uploader.thumb.to_s))).to be true

          # doesn't depend on arguments order
          FileUtils.rm([@uploader.small_thumb.path, @uploader.thumb.path])
          @uploader.recreate_versions!(:thumb, :small_thumb)
          expect(File.exist?(public_path(@uploader.small_thumb.to_s))).to be true
          expect(File.exist?(public_path(@uploader.thumb.to_s))).to be true
        end

        it "doesn't touch other versions" do
          @uploader_class.version(:another)
          @uploader.store!(bork_file)
          FileUtils.rm(@uploader.another.path)
          @uploader.recreate_versions!(:small_thumb)
          expect(File.exist?(public_path(@uploader.another.to_s))).to be false
        end
      end

      context "with a grandchild version" do
        it "should process all the files needed for recreation" do
          @uploader_class.version(:grandchild, from_version: :small_thumb)
          @uploader.store!(bork_file)
          FileUtils.rm([@uploader.small_thumb.path, @uploader.thumb.path])
          @uploader.recreate_versions!(:grandchild)
          expect(File.exist?(public_path(@uploader.thumb.to_s))).to be true
          expect(File.exist?(public_path(@uploader.small_thumb.to_s))).to be true
          expect(File.exist?(public_path(@uploader.grandchild.to_s))).to be true
        end
      end
    end
  end

  describe 'with a version using #convert' do
    before do
      @uploader_class.class_eval do
        include CarrierWave::MiniMagick
      end

      @uploader_class.version(:thumb) do
        process convert: :png
      end

      @another_uploader = @uploader_class.new
    end

    it 'caches the file with given extension' do
      @uploader.cache!(File.open(file_path('landscape.jpg')))
      expect(File.basename(@uploader.thumb.cache_path)).to eq 'thumb_landscape.png'
      expect(File.basename(@uploader.thumb.url)).to eq 'thumb_landscape.png'
      expect(@uploader.thumb).to be_format('png')
    end

    it 'retrieves the cached file' do
      @uploader.cache!(File.open(file_path('landscape.jpg')))
      @another_uploader.retrieve_from_cache!(@uploader.cache_name)
      expect(@another_uploader.url).to eq @uploader.url
      expect(@another_uploader.thumb.url).to eq @uploader.thumb.url
    end

    it 'stores the file with given extension' do
      @uploader.store!(File.open(file_path('landscape.jpg')))
      expect(File.basename(@uploader.thumb.store_path)).to eq 'thumb_landscape.png'
      expect(File.basename(@uploader.thumb.url)).to eq 'thumb_landscape.png'
      expect(@uploader.thumb).to be_format('png')
    end

    it 'retrieves the stored file' do
      @uploader.store!(File.open(file_path('landscape.jpg')))
      @another_uploader.retrieve_from_store!(@uploader.identifier)
      expect(@another_uploader.identifier).to eq @uploader.identifier
      expect(@another_uploader.url).to eq @uploader.url
      expect(@another_uploader.thumb.url).to eq @uploader.thumb.url
    end

    context 'with base filename overridden' do
      before do
        @uploader_class.class_eval do
          def filename
            "image.#{file.extension}"
          end
        end
      end

      it "stores the file" do
        @uploader.store!(File.open(file_path('landscape.jpg')))
        expect(File.basename(@uploader.thumb.url)).to eq 'thumb_image.png'
      end

      it "retrieves the file without inconsistency" do
        @uploader.store!(File.open(file_path('landscape.jpg')))
        @another_uploader.retrieve_from_store!(@uploader.identifier)
        expect(@another_uploader.identifier).to eq @uploader.identifier
        expect(@another_uploader.url).to eq @uploader.url
        expect(@another_uploader.thumb.url).to eq @uploader.thumb.url
      end
    end

    context 'with version full_filename overridden' do
      before do
        @uploader_class.version(:thumb) do
          def full_filename(for_file)
            'thumb_image.png'
          end
        end
      end

      it "stores the file" do
        @uploader.store!(File.open(file_path('landscape.jpg')))
        expect(File.basename(@uploader.thumb.url)).to eq 'thumb_image.png'
      end

      it "retrieves the file without inconsistency" do
        @uploader.store!(File.open(file_path('landscape.jpg')))
        @another_uploader.retrieve_from_store!(@uploader.identifier)
        expect(@another_uploader.identifier).to eq @uploader.identifier
        expect(@another_uploader.url).to eq @uploader.url
        expect(@another_uploader.thumb.url).to eq @uploader.thumb.url
      end
    end
  end

  describe 'with a version with file extension change' do
    before do
      @uploader_class.class_eval do
        def rename_to_bin
          file.move_to("#{File.basename(file.filename, '.*')}.bin")
        end
      end

      @uploader_class.version(:thumb) do
        process :rename_to_bin
      end
    end

    it "does not change the version's #filename" do
      @uploader.cache!(File.open(file_path('landscape.jpg')))
      expect(@uploader.thumb.file.filename).to eq 'landscape.bin'
      expect(@uploader.thumb.filename).to eq 'landscape.jpg'
      expect(File.basename(@uploader.thumb.store_path)).to eq 'thumb_landscape.jpg'
    end

    context "but applying #force_extension" do
      before do
        @uploader_class.version(:thumb) do
          force_extension '.bin'
        end
      end

      it "changes #filename to have the extension" do
        @uploader.store!(File.open(file_path('landscape.jpg')))
        expect(@uploader.thumb.identifier).to eq 'landscape.jpg'
        expect(File.basename(@uploader.thumb.store_path)).to eq 'thumb_landscape.bin'
      end
    end
  end
end
