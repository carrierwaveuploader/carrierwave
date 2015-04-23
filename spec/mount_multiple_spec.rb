# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Mount do

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '.mount_uploaders' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploaders(:images, @uploader)
      @instance = @class.new
    end

    it "should maintain the ability to super" do
      @class.class_eval do
        def images_uploader
          super
        end

        def images=(val)
          super
        end
      end

      @instance.images = [stub_file('test.jpg')]
      expect(@instance.images[0]).to be_an_instance_of(@uploader)
    end

    it "should inherit uploaders to subclasses" do
      @subclass = Class.new(@class)
      @subclass_instance = @subclass.new
      @subclass_instance.images = [stub_file('test.jpg'), stub_file('new.jpeg')]
      expect(@subclass_instance.images[0]).to be_an_instance_of(@uploader)
      expect(@subclass_instance.images[1]).to be_an_instance_of(@uploader)
    end

    it "should allow marshalling uploaders and versions" do
      Object.const_set("MyClass#{@class.object_id}".gsub('-', '_'), @class)
      Object.const_set("Uploader#{@uploader.object_id}".gsub('-', '_'), @uploader)
      @uploader.class_eval do
        def rotate
        end
      end
      @uploader.version :thumb do
        process :rotate
      end
      @instance.images = [stub_file('test.jpg')]
      expect { Marshal.dump @instance.images }.not_to raise_error
    end

    describe "expected behavior with subclassed uploaders" do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @uploader1 = Class.new(CarrierWave::Uploader::Base) do
          [:rotate, :compress, :encrypt, :shrink].each { |m| define_method(m) {} }
        end
        @uploader1.process :rotate
        @uploader1.version :thumb do
          process :compress
        end
        @uploader2 = Class.new(@uploader1)
        @uploader2.process :shrink
        @uploader2.version :secret do
          process :encrypt
        end
        @class.mount_uploaders(:images1, @uploader1)
        @class.mount_uploaders(:images2, @uploader2)
        @instance = @class.new
        @instance.images1 = [stub_file('test.jpg')]
        @instance.images2 = [stub_file('test.jpg')]
      end

      it "should inherit defined versions" do
        expect(@instance.images1[0]).to respond_to(:thumb)
        expect(@instance.images2[0]).to respond_to(:thumb)
      end

      it "should not inherit versions defined in subclasses" do
        expect(@instance.images1[0]).not_to respond_to(:secret)
        expect(@instance.images2[0]).to respond_to(:secret)
      end

      it "should inherit defined processors properly" do
        expect(@uploader1.processors).to eq([[:rotate, [], nil]])
        expect(@uploader2.processors).to eq([[:rotate, [], nil], [:shrink, [], nil]])
        expect(@uploader1.versions[:thumb].processors).to eq([[:compress, [], nil]])
        expect(@uploader2.versions[:thumb].processors).to eq([[:compress, [], nil]])
        expect(@uploader2.versions[:secret].processors).to eq([[:encrypt, [], nil]])
      end
    end

    describe '#images' do

      it "should return an empty array when nothing has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return(nil)
        expect(@instance.images).to eq []
      end

      it "should return an empty array when an empty string has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return('')
        expect(@instance.images).to eq []
      end

      it "should retrieve a file from the storage if a value is stored in the database" do
        expect(@instance).to receive(:read_uploader).with(:images).at_least(:once).and_return(['test.jpg', 'new.jpeg'])
        expect(@instance.images[0]).to be_an_instance_of(@uploader)
        expect(@instance.images[1]).to be_an_instance_of(@uploader)
      end

      it "should set the path to the store dir" do
        expect(@instance).to receive(:read_uploader).with(:images).at_least(:once).and_return('test.jpg')
        expect(@instance.images[0].current_path).to eq(public_path('uploads/test.jpg'))
      end

    end

    describe '#images=' do

      it "should cache files" do
        @instance.images = [stub_file('test.jpg'), stub_file('old.jpeg')]
        expect(@instance.images[0]).to be_an_instance_of(@uploader)
        expect(@instance.images[1]).to be_an_instance_of(@uploader)
      end

      it "should copy files into the cache directory" do
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images[0].current_path).to match(/^#{public_path('uploads/tmp')}/)
      end

      it "should do nothing when nil is assigned" do
        expect(@instance).not_to receive(:write_uploader)
        @instance.images = nil
      end

      it "should do nothing when an empty string is assigned" do
        expect(@instance).not_to receive(:write_uploader)
        @instance.images = [stub_file('test.jpg')]
      end

      it "should fail silently if the images fails a white list integrity check" do
        @uploader.class_eval do
          def extension_white_list
            %w(txt)
          end
        end
        @instance.images = [stub_file('bork.txt'), stub_file('test.jpg')]
        expect(@instance.images).to be_empty
      end

      it "should fail silently if the images fails a black list integrity check" do
        @uploader.class_eval do
          def extension_black_list
            %w(jpg)
          end
        end
        @instance.images = [stub_file('bork.txt'), stub_file('test.jpg')]
        expect(@instance.images).to be_empty
      end

      it "should fail silently if the images fails to be processed" do
        @uploader.class_eval do
          process :monkey
          def monkey
            raise CarrierWave::ProcessingError, "Ohh noez!"
          end
        end
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images).to be_empty
      end

    end

    describe '#images?' do

      it "should be false when nothing has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return(nil)
        expect(@instance.images?).to be_falsey
      end

      it "should be false when an empty string has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return('')
        expect(@instance.images?).to be_falsey
      end

      it "should be true when a file has been cached" do
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images?).to be_truthy
      end

    end

    describe '#images_urls' do

      it "should return nil when nothing has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return(nil)
        expect(@instance.images_urls).to be_empty
      end

      it "should return nil when an empty string has been assigned" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return('')
        expect(@instance.images_urls).to be_empty
      end

      it "should get the url from a retrieved file" do
        expect(@instance).to receive(:read_uploader).at_least(:once).with(:images).and_return('test.jpg')
        expect(@instance.images_urls[0]).to eq('/uploads/test.jpg')
      end

      it "should get the url from a cached file" do
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images_urls[0]).to match(%r{uploads/tmp/[\d\-]+/test.jpg})
      end

      it "should get the url from a cached file's version" do
        @uploader.version(:thumb)
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images_urls(:thumb)[0]).to match(%r{uploads/tmp/[\d\-]+/thumb_test.jpg})
      end

    end

    describe '#images_cache' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
      end

      it "should return nil when nothing has been assigned" do
        expect(@instance.images_cache).to be_nil
      end

      it "should be nil when a file has been stored" do
        @instance.images = [stub_file('test.jpg')]
        @instance.store_images!
        expect(@instance.images_cache).to be_nil
      end

      it "should be the cache name when a file has been cached" do
        @instance.images = [stub_file('test.jpg'), stub_file('old.jpeg')]
        res = JSON.parse(@instance.images_cache)
        expect(res[0]).to match(%r(^[\d]+\-[\d]+\-[\d]{4}/test\.jpg$))
        expect(res[1]).to match(%r(^[\d]+\-[\d]+\-[\d]{4}/old\.jpeg$))
      end
    end

    describe '#images_cache=' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
        CarrierWave::SanitizedFile.new(file_path('test.jpg')).copy_to(public_path('uploads/tmp/1369894322-123-1234/test.jpg'))
      end

      it "should do nothing when nil is assigned" do
        @instance.images_cache = nil
        expect(@instance.images).to be_empty
      end

      it "should do nothing when an empty string is assigned" do
        @instance.images_cache = ''
        expect(@instance.images).to be_empty
      end

      it "retrieve from cache when a cache name is assigned" do
        @instance.images_cache = ['1369894322-123-1234/test.jpg'].to_json
        expect(@instance.images[0].current_path).to eq(public_path('uploads/tmp/1369894322-123-1234/test.jpg'))
      end

      it "should not write over a previously assigned file" do
        @instance.images = [stub_file('test.jpg')]
        @instance.images_cache = ['1369894322-123-1234/monkey.jpg'].to_json
        expect(@instance.images[0].current_path).to match(/test.jpg$/)
      end
    end

    describe 'with ShamRack' do

      before do
        sham_rack_app = ShamRack.at('www.example.com').stub
        sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')
      end

      after do
        ShamRack.unmount_all
      end

      describe '#remote_images_urls' do
        it "should return nil" do
          expect(@instance.remote_images_urls).to be_nil
        end

        it "should return previously cached URL" do
          @instance.remote_images_urls = ['http://www.example.com/test.jpg']
          expect(@instance.remote_images_urls).to eq(['http://www.example.com/test.jpg'])
        end
      end

      describe '#remote_images_urls=' do

        it "should do nothing when nil is assigned" do
          @instance.remote_images_urls = nil
          expect(@instance.images).to be_empty
        end

        it "should do nothing when an empty string is assigned" do
          @instance.remote_images_urls = ''
          expect(@instance.images).to be_empty
        end

        it "retrieve from cache when a cache name is assigned" do
          @instance.remote_images_urls = ['http://www.example.com/test.jpg']
          expect(@instance.images[0].current_path).to match(/test.jpg$/)
        end

        it "should write over a previously assigned file" do
          @instance.images = [stub_file('portrait.jpg')]
          @instance.remote_images_urls = ['http://www.example.com/test.jpg']
          expect(@instance.images[0].current_path).to match(/test.jpg$/)
        end
      end
    end

    describe '#store_images!' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.store_images!
        expect(@instance.images).to be_empty
      end

      it "store an assigned file" do
        @instance.images = [stub_file('test.jpg')]
        @instance.store_images!
        expect(@instance.images[0].current_path).to eq(public_path('uploads/test.jpg'))
      end

      it "should remove an uploaded file when remove_images? returns true" do
        @instance.images = [stub_file('test.jpg')]
        path = @instance.images[0].current_path
        @instance.remove_images = true
        @instance.store_images!
        expect(@instance.images).to be_empty
        expect(File.exist?(path)).to be_falsey
      end
    end

    describe '#remove_images!' do

      before do
        allow(@instance).to receive(:write_uploader)
        allow(@instance).to receive(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.remove_images!
        expect(@instance.images).to be_empty
      end

      it "should remove an uploaded file" do
        @instance.images = [stub_file('test.jpg')]
        path = @instance.images[0].current_path
        @instance.remove_images!
        expect(@instance.images).to be_empty
        expect(File.exist?(path)).to be_falsey
      end
    end

    describe '#remove_images' do

      it "should store a value" do
        @instance.remove_images = true
        expect(@instance.remove_images).to be_truthy
      end

    end

    describe '#remove_images?' do

      it "should be true when the value is truthy" do
        @instance.remove_images = true
        expect(@instance.remove_images?).to be_truthy
      end

      it "should be false when the value is falsey" do
        @instance.remove_images = false
        expect(@instance.remove_images?).to be_falsey
      end

      it "should be false when the value is ''" do
        @instance.remove_images = ''
        expect(@instance.remove_images?).to be_falsey
      end

      it "should be false when the value is '0'" do
        @instance.remove_images = '0'
        expect(@instance.remove_images?).to be_falsey
      end

      it "should be false when the value is 'false'" do
        @instance.remove_images = 'false'
        expect(@instance.remove_images?).to be_falsey
      end

    end

    describe '#images_integrity_error' do

      it "should be nil by default" do
        expect(@instance.images_integrity_error).to be_nil
      end

      it "should be nil after a file is cached" do
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images_integrity_error).to be_nil
      end

      describe "when an integrity check fails" do
        before do
          @uploader.class_eval do
            def extension_white_list
              %w(txt)
            end
          end
        end

        it "should be an error instance if file was cached" do
          @instance.images = [stub_file('test.jpg')]
          e = @instance.images_integrity_error
          expect(e).to be_an_instance_of(CarrierWave::IntegrityError)
          expect(e.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
        end

        it "should be an error instance if file was downloaded" do
          sham_rack_app = ShamRack.at('www.example.com').stub
          sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')

          @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
          e = @instance.images_integrity_error
          expect(e).to be_an_instance_of(CarrierWave::IntegrityError)
          expect(e.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
        end

        it "should be an error instance when images file is assigned and remote_images_urls is blank" do
          @instance.images = [stub_file('test.jpg')]
          @instance.remote_images_urls = ""
          e = @instance.images_integrity_error
          expect(e).to be_an_instance_of(CarrierWave::IntegrityError)
          expect(e.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
        end
      end
    end

    describe '#images_processing_error' do

      it "should be nil by default" do
        expect(@instance.images_processing_error).to be_nil
      end

      it "should be nil after a file is cached" do
        @instance.images = [stub_file('test.jpg')]
        expect(@instance.images_processing_error).to be_nil
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
          @instance.images = [stub_file('test.jpg')]
          expect(@instance.images_processing_error).to be_an_instance_of(CarrierWave::ProcessingError)
        end

        it "should be an error instance if file was downloaded" do
          sham_rack_app = ShamRack.at('www.example.com').stub
          sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')

          @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
          expect(@instance.images_processing_error).to be_an_instance_of(CarrierWave::ProcessingError)
        end
      end
    end

    describe '#images_download_error' do
      before do
        sham_rack_app = ShamRack.at('www.example.com').stub
        sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')
      end

      it "should be nil by default" do
        expect(@instance.images_download_error).to be_nil
      end

      it "should be nil if file download was successful" do
        @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
        expect(@instance.images_download_error).to be_nil
      end

      it "should be an error instance if file could not be found" do
        @instance.remote_images_urls = ["http://www.example.com/missing.jpg"]
        expect(@instance.images_download_error).to be_an_instance_of(CarrierWave::DownloadError)
      end
    end

    describe '#images_download_error' do
      before do
        sham_rack_app = ShamRack.at('www.example.com').stub
        sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')
      end

      it "should be nil by default" do
        expect(@instance.images_download_error).to be_nil
      end

      it "should be nil if file download was successful" do
        @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
        expect(@instance.images_download_error).to be_nil
      end

      it "should be an error instance if file could not be found" do
        @instance.remote_images_urls = ["http://www.example.com/missing.jpg"]
        expect(@instance.images_download_error).to be_an_instance_of(CarrierWave::DownloadError)
      end
    end

    describe '#write_images_identifier' do
      it "should write to the column" do
        expect(@instance).to receive(:write_uploader).with(:images, ["test.jpg"])
        @instance.images = [stub_file('test.jpg')]
        @instance.write_images_identifier
      end

      it "should remove from the column when remove_images is true" do
        @instance.images = [stub_file('test.jpg')]
        @instance.store_images!
        @instance.remove_images = true
        expect(@instance).to receive(:write_uploader).with(:images, nil)
        @instance.write_images_identifier
      end
    end

    describe '#images_identifiers' do
      it "should return the identifier from the mounted column" do
        expect(@instance).to receive(:read_uploader).with(:images).and_return("test.jpg")
        expect(@instance.images_identifiers).to eq(['test.jpg'])
      end
    end

  end

  describe '#mount_uploaders without an uploader' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      @class.mount_uploaders(:images)
      @instance = @class.new
    end

    describe '#images' do

      before do
        allow(@instance).to receive(:read_uploader).and_return('test.jpg')
      end

      it "should return an instance of a subclass of CarrierWave::Uploader::Base" do
        expect(@instance.images[0]).to be_a(CarrierWave::Uploader::Base)
      end

      it "should set the path to the store dir" do
        expect(@instance.images[0].current_path).to eq(public_path('uploads/test.jpg'))
      end

    end

  end

  describe '#mount_uploaders with a block' do
    describe 'and no uploader given' do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @class.mount_uploaders(:images) do
          def monkey
            'blah'
          end
        end
        @instance = @class.new
        @instance.images = [stub_file("test.jpg")]
      end

      it "should return an instance of a subclass of CarrierWave::Uploader::Base" do
        expect(@instance.images[0]).to be_a(CarrierWave::Uploader::Base)
      end

      it "should apply any custom modifications" do
        expect(@instance.images[0].monkey).to eq("blah")
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
        @class.mount_uploaders(:images, @uploader) do
          def fish
            'blub'
          end
        end
        @instance = @class.new
        @instance.images = [stub_file("test.jpg")]
      end

      it "should return an instance of the uploader specified" do
        expect(@instance.images[0]).to be_a_kind_of(@uploader)
      end

      it "should apply any custom modifications to the instance" do
        expect(@instance.images[0].fish).to eq("blub")
      end

      it "should apply any custom modifications to all defined versions" do
        expect(@instance.images[0].thumb.fish).to eq("blub")
        expect(@instance.images[0].thumb.mini.fish).to eq("blub")
        expect(@instance.images[0].thumb.maxi.fish).to eq("blub")
      end

      it "should not apply any custom modifications to the uploader class" do
        expect(@uploader.new).not_to respond_to(:fish)
      end
    end
  end

  describe '#mount_uploaders with :ignore_integrity_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploaders(:images, @uploader, :ignore_integrity_errors => false)
      @instance = @class.new

      @uploader.class_eval do
        def extension_white_list
          %w(txt)
        end
      end
    end

    it "should raise an error if the images fails an integrity check when cached" do
      expect(running {
        @instance.images = [stub_file('test.jpg')]
      }).to raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an error if the images fails an integrity check when downloaded" do
      sham_rack_app = ShamRack.at('www.example.com').stub
      sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')

      expect(running {
        @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
      }).to raise_error(CarrierWave::IntegrityError)
    end
  end

  describe '#mount_uploaders with :ignore_processing_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploaders(:images, @uploader, :ignore_processing_errors => false)
      @instance = @class.new

      @uploader.class_eval do
        process :monkey
        def monkey
          raise CarrierWave::ProcessingError, "Ohh noez!"
        end
      end
    end

    it "should raise an error if the images fails to be processed when cached" do
      expect(running {
        @instance.images = [stub_file('test.jpg')]
      }).to raise_error(CarrierWave::ProcessingError)
    end

    it "should raise an error if the images fails to be processed when downloaded" do
      sham_rack_app = ShamRack.at('www.example.com').stub
      sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')

      expect(running {
        @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
      }).to raise_error(CarrierWave::ProcessingError)
    end

  end

  describe '#mount_uploaders with :ignore_download_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploaders(:images, @uploader, :ignore_download_errors => false)
      @instance = @class.new
    end

    it "should raise an error if the images fails to be processed" do
      @uploader.class_eval do
        def download! uri
          raise CarrierWave::DownloadError
        end
      end

      expect(running {
        @instance.remote_images_urls = ["http://www.example.com/test.jpg"]
      }).to raise_error(CarrierWave::DownloadError)
    end

  end

  describe '#mount_uploaders with :mount_on => :monkey' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploaders(:images, @uploader, :mount_on => :monkey)
      @instance = @class.new
    end

    describe '#images' do
      it "should retrieve a file from the storage if a value is stored in the database" do
        expect(@instance).to receive(:read_uploader).at_least(:once).with(:monkey).and_return(['test.jpg'])
        expect(@instance.images[0]).to be_an_instance_of(@uploader)
        expect(@instance.images[0].current_path).to eq(public_path('uploads/test.jpg'))
      end
    end

    describe '#write_images_identifier' do
      it "should write to the given column" do
        expect(@instance).to receive(:write_uploader).with(:monkey, ["test.jpg"])
        @instance.images = [stub_file('test.jpg')]
        @instance.write_images_identifier
      end

      it "should remove from the given column when remove_images is true" do
        @instance.images = [stub_file('test.jpg')]
        @instance.store_images!
        @instance.remove_images = true
        expect(@instance).to receive(:write_uploader).with(:monkey, nil)
        @instance.write_images_identifier
      end
    end

  end

end
