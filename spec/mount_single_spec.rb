require 'spec_helper'

describe CarrierWave::Mount do

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '.mount_uploader' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader)
      @instance = @class.new
    end

    it "should maintain the ability to super" do
      @class.class_eval do
        def image_uploader
          super
        end

        def image=(val)
          super
        end
      end

      @instance.image = stub_file('test.jpg')
      expect(@instance.image).to be_an_instance_of(@uploader)
    end

    it "should inherit uploaders to subclasses" do
      @subclass = Class.new(@class)
      @subclass_instance = @subclass.new
      @subclass_instance.image = stub_file('test.jpg')
      expect(@subclass_instance.image).to be_an_instance_of(@uploader)
    end

    it "should allow marshalling uploaders and versions" do
      Object.const_set("MyClass#{@class.object_id}".tr('-', '_'), @class)
      Object.const_set("Uploader#{@uploader.object_id}".tr('-', '_'), @uploader)
      @uploader.class_eval do
        def rotate
        end
      end
      @uploader.version :thumb do
        process :rotate
      end
      @instance.image = stub_file('test.jpg')
      expect { Marshal.dump @instance.image }.not_to raise_error
    end

    describe "expected behavior with subclassed uploaders" do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @uploader1 = Class.new(CarrierWave::Uploader::Base)
        @uploader1.process :rotate
        @uploader1.version :thumb do
          process :compress
        end
        @uploader2 = Class.new(@uploader1)
        @uploader2.process :shrink
        @uploader2.version :secret do
          process :encrypt
        end
        @class.mount_uploader(:image1, @uploader1)
        @class.mount_uploader(:image2, @uploader2)
        @instance = @class.new
      end

      it "should inherit defined versions" do
        expect(@instance.image1).to respond_to(:thumb)
        expect(@instance.image2).to respond_to(:thumb)
      end

      it "should not inherit versions defined in subclasses" do
        expect(@instance.image1).not_to respond_to(:secret)
        expect(@instance.image2).to respond_to(:secret)
      end

      it "should inherit defined processors properly" do
        expect(@uploader1.processors).to eq([[:rotate, [], nil]])
        expect(@uploader2.processors).to eq([[:rotate, [], nil], [:shrink, [], nil]])
        expect(@uploader1.versions[:thumb].processors).to eq([[:compress, [], nil]])
        expect(@uploader2.versions[:thumb].processors).to eq([[:compress, [], nil]])
        expect(@uploader2.versions[:secret].processors).to eq([[:encrypt, [], nil]])
      end
    end

    describe '#image' do

      it "should return a blank uploader when nothing has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:image).and_return(nil)
        expect(@instance.image).to be_an_instance_of(@uploader)
        expect(@instance.image).to be_blank
      end

      it "should return the same object every time when nothing has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:image).and_return(nil)
        expect(@instance.image.object_id).to eq @instance.image.object_id
      end

      it "should return a blank uploader when an empty string has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:image).and_return('')
        expect(@instance.image).to be_an_instance_of(@uploader)
        expect(@instance.image).to be_blank
      end

      it "should retrieve a file from the storage if a value is stored in the database" do
        expect(@instance).to receive(:read_uploader).with(:image).at_least(:once).and_return('test.jpg')
        expect(@instance.image).to be_an_instance_of(@uploader)
      end

      it "should set the path to the store dir" do
        expect(@instance).to receive(:read_uploader).with(:image).at_least(:once).and_return('test.jpg')
        expect(@instance.image.current_path).to eq(public_path('uploads/test.jpg'))
      end

    end

    describe '#image=' do

      it "should cache a file" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image).to be_an_instance_of(@uploader)
      end

      it "should copy a file into into the cache directory" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image.current_path).to match(/^#{public_path('uploads/tmp')}/)
      end

      it "should do nothing when nil is assigned" do
        expect(@instance).not_to receive(:write_uploader)
        @instance.image = nil
      end

      it "should do nothing when an empty string is assigned" do
        expect(@instance).not_to receive(:write_uploader)
        @instance.image = stub_file('test.jpg')
      end

      it "should fail silently if the image fails an allowlist integrity check" do
        @uploader.class_eval do
          def extension_allowlist
            %w(txt)
          end
        end
        @instance.image = stub_file('test.jpg')
        expect(@instance.image).to be_blank
      end

      it "should fail silently if the image fails a denylist integrity check" do
        @uploader.class_eval do
          def extension_denylist
            %w(jpg)
          end
        end
        @instance.image = stub_file('test.jpg')
        expect(@instance.image).to be_blank
      end

      it "should fail silently if the image fails to be processed" do
        @uploader.class_eval do
          process :monkey
          def monkey
            raise CarrierWave::ProcessingError, "Ohh noez!"
          end
        end
        @instance.image = stub_file('test.jpg')
      end

    end

    describe '#image?' do

      it "should be false when nothing has been assigned" do
        @instance.image = nil
        expect(@instance.image?).to be_falsey
      end

      it "should be false when an empty string has been assigned" do
        @instance.image = ''
        expect(@instance.image?).to be_falsey
      end

      it "should be true when a file has been cached" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image?).to be_truthy
      end

    end

    describe '#image_url' do

      it "should return nil when nothing has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:image).and_return(nil)
        expect(@instance.image_url).to be_nil
      end

      it "should return fallback url when nothing has been assigned" do
        @uploader.class_eval do
          def default_url
            "foo/bar.jpg"
          end
        end
        expect(@instance).to receive(:read_uploader).with(:image).and_return(nil)
        expect(@instance.image_url).to eq("foo/bar.jpg")
      end

      it "should return nil when an empty string has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:image).and_return('')
        expect(@instance.image_url).to be_nil
      end

      it "should get the url from a retrieved file" do
        expect(@instance).to receive(:read_uploader).at_least(:once).with(:image).and_return('test.jpg')
        expect(@instance.image_url).to eq('/uploads/test.jpg')
      end

      it "should get the url from a cached file" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image_url).to match(%r{uploads/tmp/[\d\-]+/test.jpg})
      end

      it "should get the url from a cached file's version" do
        @uploader.version(:thumb)
        @instance.image = stub_file('test.jpg')
        expect(@instance.image_url(:thumb)).to match(%r{uploads/tmp/[\d\-]+/thumb_test.jpg})
      end

    end

    describe '#image_cache' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
      end

      it "should return nil when nothing has been assigned" do
        expect(@instance.image_cache).to be_nil
      end

      it "should be nil when a file has been stored" do
        @instance.image = stub_file('test.jpg')
        @instance.image.store!
        expect(@instance.image_cache).to be_nil
      end

      it "should be the cache name when a file has been cached" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image_cache).to match(%r(^[\d]+\-[\d]+\-[\d]{4}\-[\d]{4}/test\.jpg$))
      end

    end

    describe '#image_cache=' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
        CarrierWave::SanitizedFile.new(file_path('test.jpg')).copy_to(public_path('uploads/tmp/1369894322-123-0123-1234/test.jpg'))
      end

      it "should do nothing when nil is assigned" do
        @instance.image_cache = nil
        expect(@instance.image).to be_blank
      end

      it "should do nothing when an empty string is assigned" do
        @instance.image_cache = ''
        expect(@instance.image).to be_blank
      end

      it "retrieve from cache when a cache name is assigned" do
        @instance.image_cache = '1369894322-123-0123-1234/test.jpg'
        expect(@instance.image.current_path).to eq(public_path('uploads/tmp/1369894322-123-0123-1234/test.jpg'))
      end

      it "should not write over a previously assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.image_cache = '1369894322-123-0123-1234/monkey.jpg'
        expect(@instance.image.current_path).to match(/test.jpg$/)
      end

      it "should not clear a previously stored file when an empty string is assigned" do
        @instance.image = stub_file('test.jpg')
        @instance.image.store!
        @instance.image_cache = ''
        expect(@instance.image.current_path).to match(/test.jpg$/)
      end
    end

    describe "#remote_image_url" do
      before do
        stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
      end

      it "returns nil" do
        expect(@instance.remote_image_url).to be_nil
      end

      it "returns previously cached URL" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"

        expect(@instance.remote_image_url).to eq("http://www.example.com/test.jpg")
      end

      describe "URI with unicode symbols" do
        before do
          stub_request(
            :get,
            "http://www.example.com/%D1%8E%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4.jpg"
          ).to_return(body: File.read(file_path("юникод.jpg")))
        end

        it "works correctly" do
          @instance.remote_image_url = "http://www.example.com/%D1%8E%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4.jpg"
          expect(@instance.remote_image_url).to eq("http://www.example.com/%D1%8E%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4.jpg")
        end

        it "decodes it correctly" do
          @instance.remote_image_url = "http://www.example.com/%D1%8E%D0%BD%D0%B8%D0%BA%D0%BE%D0%B4.jpg"
          expect(@instance.image.current_path).to match(/юникод.jpg$/)
        end
      end
    end

    describe "#remote_image_url=" do
      before do
        stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
      end

      it "does nothing when nil is assigned" do
        @instance.remote_image_url = nil

        expect(@instance.image).to be_blank
      end

      it "does nothing when an empty string is assigned" do
        @instance.remote_image_url = ""

        expect(@instance.image).to be_blank
      end

      it "retrieves from cache when a cache name is assigned" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"

        expect(@instance.image.current_path).to match(/test.jpg$/)
      end

      it "does not write over a previously assigned file" do
        @instance.image = stub_file("portrait.jpg")
        @instance.remote_image_url = "http://www.example.com/test.jpg"

        expect(@instance.image.current_path).to match(/portrait.jpg$/)
      end

      it "does not clear a previously stored file when an empty string is assigned" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"
        @instance.image.store!
        @instance.remote_image_url = ""
        expect(@instance.image.current_path).to match(/test.jpg$/)
      end
    end

    describe '#store_image!' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.store_image!
        expect(@instance.image).to be_blank
      end

      it "store an assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        expect(@instance.image.current_path).to eq(public_path('uploads/test.jpg'))
      end
    end

    describe '#remove_image!' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.remove_image!
        expect(@instance.image).to be_blank
      end

      it "should remove an uploaded file" do
        @instance.image = stub_file('test.jpg')
        path = @instance.image.current_path
        @instance.remove_image!
        expect(@instance.image).to be_blank
        expect(File.exist?(path)).to be_falsey
      end
    end

    describe '#remove_image' do

      it "should store a value" do
        @instance.remove_image = true
        expect(@instance.remove_image).to be_truthy
      end

    end

    describe '#remove_image?' do

      it "should be true when the value is truthy" do
        @instance.remove_image = true
        expect(@instance.remove_image?).to be_truthy
      end

      it "should be false when the value is falsey" do
        @instance.remove_image = false
        expect(@instance.remove_image?).to be_falsey
      end

      it "should be false when the value is ''" do
        @instance.remove_image = ''
        expect(@instance.remove_image?).to be_falsey
      end

      it "should be false when the value is '0'" do
        @instance.remove_image = '0'
        expect(@instance.remove_image?).to be_falsey
      end

      it "should be false when the value is 'false'" do
        @instance.remove_image = 'false'
        expect(@instance.remove_image?).to be_falsey
      end

    end

    describe '#image_integrity_error' do

      it "should be nil by default" do
        expect(@instance.image_integrity_error).to be_nil
      end

      it "should be nil after a file is cached" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image_integrity_error).to be_nil
      end

      describe "when an integrity check fails" do
        before do
          @uploader.class_eval do
            def extension_allowlist
              %w(txt)
            end
          end
        end

        it "should be an error instance if file was cached" do
          @instance.image = stub_file('test.jpg')
          e = @instance.image_integrity_error
          expect(e).to be_an_instance_of(CarrierWave::IntegrityError)
          expect(e.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
        end

        it "should be an error instance if file was downloaded" do
          stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
          @instance.remote_image_url = "http://www.example.com/test.jpg"
          e = @instance.image_integrity_error

          expect(e).to be_an_instance_of(CarrierWave::IntegrityError)
          expect(e.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
        end

        it "should be an error instance when image file is assigned and remote_image_url is blank" do
          @instance.image = stub_file('test.jpg')
          @instance.remote_image_url = ""
          e = @instance.image_integrity_error
          expect(e).to be_an_instance_of(CarrierWave::IntegrityError)
          expect(e.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
        end
      end
    end

    describe '#image_processing_error' do

      it "should be nil by default" do
        expect(@instance.image_processing_error).to be_nil
      end

      it "should be nil after a file is cached" do
        @instance.image = stub_file('test.jpg')
        expect(@instance.image_processing_error).to be_nil
      end

      describe "when an processing error occurs" do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError, "Ohh noez!"
            end
          end
        end

        it "should be an error instance if file was cached" do
          @instance.image = stub_file('test.jpg')
          expect(@instance.image_processing_error).to be_an_instance_of(CarrierWave::ProcessingError)
        end

        it "should be an error instance if file was downloaded" do
          stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
          @instance.remote_image_url = "http://www.example.com/test.jpg"

          expect(@instance.image_processing_error).to be_an_instance_of(CarrierWave::ProcessingError)
        end
      end
    end

    describe '#image_download_error' do
      before do
        stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
        stub_request(:get, "http://www.example.com/missing.jpg").to_return(status: 404)
      end

      it "should be nil by default" do
        expect(@instance.image_download_error).to be_nil
      end

      it "should be nil if file download was successful" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"
        expect(@instance.image_download_error).to be_nil
      end

      it "should be an error instance if file could not be found" do
        @instance.remote_image_url = "http://www.example.com/missing.jpg"
        expect(@instance.image_download_error).to be_an_instance_of(CarrierWave::DownloadError)
      end
    end

    describe '#image_download_error' do
      before do
        stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
        stub_request(:get, "http://www.example.com/missing.jpg").to_return(status: 404)
      end

      it "should be nil by default" do
        expect(@instance.image_download_error).to be_nil
      end

      it "should be nil if file download was successful" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"
        expect(@instance.image_download_error).to be_nil
      end

      it "should be an error instance if file could not be found" do
        @instance.remote_image_url = "http://www.example.com/missing.jpg"
        expect(@instance.image_download_error).to be_an_instance_of(CarrierWave::DownloadError)
      end
    end

    describe '#write_image_identifier' do
      it "should write to the column" do
        expect(@instance).to receive(:write_uploader).with(:image, "test.jpg")
        @instance.image = stub_file('test.jpg')
        @instance.write_image_identifier
      end

      it "should remove from the column when remove_image is true" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        @instance.remove_image = true
        expect(@instance).to receive(:write_uploader).with(:image, nil)
        @instance.write_image_identifier
        expect(@instance.image).to be_blank
      end
    end

    describe '#image_identifier' do
      it "should return the identifier from the mounted column" do
        expect(@instance).to receive(:read_uploader).with(:image).and_return("test.jpg")
        expect(@instance.image_identifier).to eq('test.jpg')
      end
    end

  end

  describe '#mount_uploader without an uploader' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      @class.mount_uploader(:image)
      @instance = @class.new
    end

    describe '#image' do

      before do
        allow(@instance).to receive(:read_uploader).and_return('test.jpg')
      end

      it "should return an instance of a subclass of CarrierWave::Uploader::Base" do
        expect(@instance.image).to be_a(CarrierWave::Uploader::Base)
      end

      it "should set the path to the store dir" do
        expect(@instance.image.current_path).to eq(public_path('uploads/test.jpg'))
      end

    end

  end

  describe '#mount_uploader with a block' do
    describe 'and no uploader given' do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @class.mount_uploader(:image) do
          def monkey
            'blah'
          end
        end
        @instance = @class.new
      end

      it "should return an instance of a subclass of CarrierWave::Uploader::Base" do
        expect(@instance.image).to be_a(CarrierWave::Uploader::Base)
      end

      it "should apply any custom modifications" do
        expect(@instance.image.monkey).to eq("blah")
      end
    end

    describe 'and an uploader given' do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @uploader = Class.new(CarrierWave::Uploader::Base)
        @uploader.version :thumb do
          version :mini
          version :maxi
        end
        @class.mount_uploader(:image, @uploader) do
          def fish
            'blub'
          end
        end
        @instance = @class.new
      end

      it "should return an instance of the uploader specified" do
        expect(@instance.image).to be_a_kind_of(@uploader)
      end

      it "should apply any custom modifications to the instance" do
        expect(@instance.image.fish).to eq("blub")
      end

      it "should apply any custom modifications to all defined versions" do
        expect(@instance.image.thumb.fish).to eq("blub")
        expect(@instance.image.thumb.mini.fish).to eq("blub")
        expect(@instance.image.thumb.maxi.fish).to eq("blub")
      end

      it "should not apply any custom modifications to the uploader class" do
        expect(@uploader.new).not_to respond_to(:fish)
      end
    end
  end

  describe '#mount_uploader with :ignore_integrity_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :ignore_integrity_errors => false)
      @instance = @class.new

      @uploader.class_eval do
        def extension_allowlist
          %w(txt)
        end
      end
    end

    it "should raise an error if the image fails an integrity check when cached" do
      expect(running {
        @instance.image = stub_file('test.jpg')
      }).to raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an error if the image fails an integrity check when downloaded" do
      stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))

      expect(running {
        @instance.remote_image_url = "http://www.example.com/test.jpg"
      }).to raise_error(CarrierWave::IntegrityError)
    end
  end

  describe '#mount_uploader with :ignore_processing_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :ignore_processing_errors => false)
      @instance = @class.new

      @uploader.class_eval do
        process :monkey
        def monkey
          raise CarrierWave::ProcessingError, "Ohh noez!"
        end
      end
    end

    it "should raise an error if the image fails to be processed when cached" do
      expect(running {
        @instance.image = stub_file('test.jpg')
      }).to raise_error(CarrierWave::ProcessingError)
    end

    it "should raise an error if the image fails to be processed when downloaded" do
      stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))

      expect(running {
        @instance.remote_image_url = "http://www.example.com/test.jpg"
      }).to raise_error(CarrierWave::ProcessingError)
    end

  end

  describe '#mount_uploader with :ignore_download_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :ignore_download_errors => false)
      @instance = @class.new
    end

    it "should raise an error if the image fails to be processed" do
      @uploader.class_eval do
        def download! uri, headers = {}
          raise CarrierWave::DownloadError
        end
      end

      expect(running {
        @instance.remote_image_url = "http://www.example.com/test.jpg"
      }).to raise_error(CarrierWave::DownloadError)
    end

  end

  describe '#mount_uploader with :mount_on => :monkey' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :mount_on => :monkey)
      @instance = @class.new
    end

    describe '#image' do
      it "should retrieve a file from the storage if a value is stored in the database" do
        expect(@instance).to receive(:read_uploader).at_least(:once).with(:monkey).and_return('test.jpg')
        expect(@instance.image).to be_an_instance_of(@uploader)
        expect(@instance.image.current_path).to eq(public_path('uploads/test.jpg'))
      end
    end

    describe '#write_image_identifier' do
      it "should write to the given column" do
        expect(@instance).to receive(:write_uploader).with(:monkey, "test.jpg")
        @instance.image = stub_file('test.jpg')
        @instance.write_image_identifier
      end

      it "should remove from the given column when remove_image is true" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        @instance.remove_image = true
        expect(@instance).to receive(:write_uploader).with(:monkey, nil)
        @instance.write_image_identifier
      end
    end

  end

end
