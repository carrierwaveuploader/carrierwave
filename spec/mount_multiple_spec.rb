require 'spec_helper'

describe CarrierWave::Mount do
  let(:klass) { Class.new.send(:extend, CarrierWave::Mount) }
  let(:uploader) { Class.new(CarrierWave::Uploader::Base) }
  let(:instance) { klass.new }
  let(:test_file_name) { 'test.jpg' }
  let(:new_file_name) { 'new.jpeg' }
  let(:test_file_stub) { stub_file(test_file_name) }
  let(:new_file_stub) { stub_file(new_file_name) }

  after { FileUtils.rm_rf(public_path) }

  describe '.mount_uploaders' do
    before { klass.mount_uploaders(:images, uploader) }

    describe "super behavior" do
      before do
        klass.class_eval do
          def images_uploader
            super
          end

          def images=(val)
            super
          end
        end

        instance.images = [stub_file(test_file_name)]
      end

      it "maintains the ability to super" do
        expect(instance.images[0]).to be_an_instance_of(uploader)
      end
    end

    describe "upload inheritance" do
      let(:subclass) { Class.new(klass) }
      let(:subclass_instance) { subclass.new }

      before { subclass_instance.images = [test_file_stub, new_file_stub] }

      it "inherits uploaders to subclasses" do
        expect(subclass_instance.images[0]).to be_an_instance_of(uploader)
        expect(subclass_instance.images[1]).to be_an_instance_of(uploader)
      end
    end

    describe "upload marshalling" do
      before do
        Object.const_set("MyClass#{klass.object_id}".gsub('-', '_'), klass)
        Object.const_set("Uploader#{uploader.object_id}".gsub('-', '_'), uploader)

        uploader.class_eval do
          def rotate
          end
        end

        uploader.version :thumb do
          process :rotate
        end

        instance.images = [test_file_stub]
      end

      it "allows marshalling uploaders and versions" do
        expect { Marshal.dump(instance.images) }.not_to raise_error
      end
    end

    describe "behavior of subclassed uploaders" do
      let(:uploader_1) do
        Class.new(CarrierWave::Uploader::Base) do
          [:rotate, :compress, :encrypt, :shrink].each { |m| define_method(m) {} }
        end.tap do |uploader|
          uploader.process :rotate
          uploader.version :thumb do
            process :compress
          end
        end
      end

      let(:uploader_2) do
        Class.new(uploader_1).tap do |uploader|
          uploader.process :shrink
          uploader.version :secret do
            process :encrypt
          end
        end
      end

      let(:instance) do
        klass.new.tap do |instance|
          instance.images1 = [test_file_stub]
          instance.images2 = [test_file_stub]
        end
      end

      before do
        klass.mount_uploaders(:images1, uploader_1)
        klass.mount_uploaders(:images2, uploader_2)
      end

      context "defined version inheritance works" do
        it { expect(instance.images1[0]).to respond_to(:thumb) }

        it { expect(instance.images2[0]).to respond_to(:thumb) }
      end

      context "version inheritance defined in subclasses works" do
        it { expect(instance.images1[0]).not_to respond_to(:secret) }

        it { expect(instance.images2[0]).to respond_to(:secret) }
      end

      context "defined processors inheritance works" do
        it { expect(uploader_1.processors).to eq([[:rotate, [], nil]]) }

        it { expect(uploader_2.processors).to eq([[:rotate, [], nil], [:shrink, [], nil]]) }

        it { expect(uploader_1.versions[:thumb].processors).to eq([[:compress, [], nil]]) }

        it { expect(uploader_2.versions[:thumb].processors).to eq([[:compress, [], nil]]) }

        it { expect(uploader_2.versions[:secret].processors).to eq([[:encrypt, [], nil]]) }
      end
    end

    describe '#images' do
      context "return an empty array when nothing has been assigned" do
        before do
          allow(instance).to receive(:read_uploader).with(:images).and_return(nil)
        end

        it { expect(instance.images).to eq [] }
      end

      context "returns an empty array when an empty string has been assigned" do
        before do
          allow(instance).to receive(:read_uploader).with(:images).and_return('')
        end

        it { expect(instance.images).to eq [] }
      end

      context "retrieves a file from the storage if a value is stored in the database" do
        subject(:images) { instance.images }

        before do
          allow(instance).to receive(:read_uploader).with(:images).at_least(:once).and_return([test_file_name, new_file_name])
        end

        it { expect(images[0]).to be_an_instance_of(uploader) }
        it { expect(images[1]).to be_an_instance_of(uploader) }
      end

      context "sets the path to the store dir" do
        subject(:image) { instance.images.first }

        before do
          allow(instance).to receive(:read_uploader).with(:images).at_least(:once).and_return(test_file_name)
        end

        it { expect(image.current_path).to eq(public_path("uploads/#{test_file_name}")) }
      end
    end

    describe '#images=' do
      let(:old_image_stub) { stub_file('old.jpeg') }
      let(:text_file_stub) { stub_file('bork.txt') }

      context "caching images" do
        before do
          instance.images = [test_file_stub, old_image_stub]
        end

        it { expect(instance.images[0]).to be_an_instance_of(uploader) }

        it { expect(instance.images[1]).to be_an_instance_of(uploader) }

        it "copies files into the cache directory" do
          expect(instance.images[0].current_path).to match(/^#{public_path('uploads/tmp')}/)
        end

        it "marks the uploader as staged" do
          expect(instance.images[0].staged).to be true
          expect(instance.images[1].staged).to be true
        end
      end

      it "does nothing when nil is assigned" do
        expect(instance).not_to receive(:write_uploader)
        instance.images = nil
      end

      it "does nothing when an empty string is assigned" do
        expect(instance).not_to receive(:write_uploader)

        instance.images = [test_file_stub]
      end

      context "fails silently if the images fails a white list integrity check" do
        before do
          uploader.class_eval do
            def extension_whitelist
              %w(txt)
            end
          end

          instance.images = [text_file_stub, test_file_stub]
        end

        it { expect(instance.images).to be_empty }
      end

      describe "fails silently if the images fails a black list integrity check" do
        before do
          uploader.class_eval do
            def extension_blacklist
              %w(jpg)
            end
          end

          instance.images = [text_file_stub, test_file_stub]
        end

        it { expect(instance.images).to be_empty }
      end

      describe "fails silently if the images fails to be processed" do
        before do
          uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError, "Ohh noez!"
            end
          end

          instance.images = [test_file_stub]
        end

        it { expect(instance.images).to be_empty }
      end

      describe "with stored files" do
        before do
          instance.images = [text_file_stub, test_file_stub]
          instance.store_images!
        end
        let(:identifiers) { instance.images.map(&:identifier) }

        it "writes over a previously stored file" do
          instance.images = [old_image_stub]
          instance.store_images!
          expect(instance.images.map(&:identifier)).to eq ['old.jpeg']
        end

        it "preserves existing image of given identifier" do
          instance.images = [identifiers[0], old_image_stub]
          instance.store_images!
          expect(instance.images.map(&:identifier)).to eq ['bork.txt','old.jpeg']
        end

        it "reorders existing image" do
          instance.images = identifiers.reverse
          instance.store_images!
          expect(instance.images.map(&:identifier)).to eq ['test.jpg', 'bork.txt']
        end

        it "allows uploading and reordering at once" do
          instance.images = [identifiers[1], old_image_stub, identifiers[0]]
          instance.store_images!
          expect(instance.images.map(&:identifier)).to eq ['test.jpg', 'old.jpeg', 'bork.txt']
        end

        it "allows repeating the same identifiers" do
          instance.images = ['bork.txt', 'test.jpg', 'bork.txt']
          instance.store_images!
          expect(instance.images.map(&:identifier)).to eq ['bork.txt', 'test.jpg', 'bork.txt']
        end

        it "removes image which is unused" do
          @image_paths = instance.images.map(&:current_path)
          instance.images = [identifiers[0]]
          instance.store_images!
          instance.send(:_mounter, :images).remove_previous(identifiers, identifiers[0..0])
          expect(instance.images.map(&:identifier)).to eq ['bork.txt']
          expect(File.exist?(@image_paths[0])).to be_truthy
          expect(File.exist?(@image_paths[1])).to be_falsey
        end

        it "ignores unknown identifier" do
          instance.images = ['unknown.txt']
          expect { instance.store_images! }.not_to raise_error
          expect(instance.images.map(&:identifier)).to be_empty
        end
      end
    end

    describe '#images?' do
      subject { instance.images? }

      context "false when nothing has been assigned" do
        before { instance.images = nil }

        it { is_expected.to be_falsey }
      end

      context "false when an empty string has been assigned" do
        before { instance.images = '' }

        it { is_expected.to be_falsey }
      end

      context "true when a file has been cached" do
        before { instance.images = [test_file_stub] }

        it { is_expected.to be_truthy }
      end
    end

    describe '#images_urls' do
      subject(:images_urls) { instance.images_urls }

      describe "returns nil when nothing has been assigned" do
        before do
          allow(instance).to receive(:read_uploader).with(:images).and_return(nil)
        end

        it { is_expected.to be_empty }
      end

      describe "should return nil when an empty string has been assigned" do
        before do
          allow(instance).to receive(:read_uploader).with(:images).and_return('')
        end

        it { is_expected.to be_empty }
      end

      describe "gets the url from a retrieved file" do
        before do
          allow(instance).to receive(:read_uploader).at_least(:once).with(:images).and_return(test_file_name)
        end

        it { expect(images_urls.first).to eq("/uploads/#{test_file_name}") }
      end

      describe "gets the url from a cached file" do
        before { instance.images = [test_file_stub] }

        it { expect(images_urls[0]).to match(%r{uploads/tmp/[\d\-]+/test.jpg}) }
      end

      describe "gets the url from a cached file's version" do
        before do
          uploader.version(:thumb)
          instance.images = [test_file_stub]
        end

        it { expect(instance.images_urls(:thumb)[0]).to match(%r{uploads/tmp/[\d\-]+/thumb_test.jpg}) }
      end
    end

    describe '#images_cache' do
      before do
        allow(instance).to receive(:write_uploader)
        allow(instance).to receive(:read_uploader).and_return(nil)
      end

      context "when nothing has been assigned" do
        it { expect(instance.images_cache).to be_nil }
      end

      context "when a file has been stored" do
        before do
          instance.images = [test_file_stub]
          instance.store_images!
        end

        it { expect(instance.images_cache).to be_nil }
      end

      context "when a file has been cached" do
        let(:json_response) { JSON.parse(instance.images_cache) }

        before do
          instance.images = [test_file_stub, stub_file('old.jpeg')]
        end

        it { expect(json_response[0]).to match(%r(^[\d]+\-[\d]+\-[\d]{4}\-[\d]{4}/test\.jpg$)) }

        it { expect(json_response[1]).to match(%r(^[\d]+\-[\d]+\-[\d]{4}\-[\d]{4}/old\.jpeg$)) }
      end
    end

    describe '#images_cache=' do
      before do
        allow(instance).to receive(:write_uploader)
        allow(instance).to receive(:read_uploader).and_return(nil)
        CarrierWave::SanitizedFile.new(test_file_stub).copy_to(public_path('uploads/tmp/1369894322-123-0123-1234/test.jpg'))
      end

      context "does nothing when nil is assigned" do
        before { instance.images_cache = nil }

        it { expect(instance.images).to be_empty }
      end

      context "does nothing when an empty string is assigned" do
        before { instance.images_cache = '' }

        it { expect(instance.images).to be_empty }
      end

      context "retrieve from cache when a cache name is assigned" do
        before { instance.images_cache = ['1369894322-123-0123-1234/test.jpg'].to_json }

        it { expect(instance.images[0].current_path).to eq(public_path('uploads/tmp/1369894322-123-0123-1234/test.jpg')) }

        it "marks the uploader as staged" do
          expect(instance.images[0].staged).to be true
        end
      end

      context "writes over a previously stored file" do
        before do
          instance.images = [test_file_stub]
          instance.store_images!
          instance.images_cache = ['1369894322-123-0123-1234/monkey.jpg'].to_json
        end

        it { expect(instance.images[0].current_path).to match(/monkey.jpg$/) }
      end

      context "doesn't write over a previously assigned file" do
        before do
          instance.images = [test_file_stub]
          instance.images_cache = ['1369894322-123-0123-1234/monkey.jpg'].to_json
        end

        it { expect(instance.images[0].current_path).to match(/test.jpg$/) }
      end
    end

    describe "#remote_images_urls" do
      subject { instance.remote_images_urls }

      before { stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: File.read(test_file_stub)) }

      context "returns nil" do
        it { is_expected.to be_nil }
      end

      context "returns previously cached URL" do
        before { instance.remote_images_urls = ["http://www.example.com/test.jpg"] }

        it { is_expected.to eq(["http://www.example.com/test.jpg"]) }
      end
    end

    describe "#remote_images_urls=" do
      subject(:images) { instance.images }

      before do
        stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: File.read(test_file_stub))
        instance.remote_images_urls = remote_images_url
      end

      context "does nothing when nil is assigned" do
        let(:remote_images_url) { nil }

        it { is_expected.to be_empty }
      end

      context "does nothing when an empty string is assigned" do
        let(:remote_images_url) { '' }

        it { is_expected.to be_empty }
      end

      context "retrieves from cache when a cache name is assigned" do
        subject { images[0].current_path }

        let(:remote_images_url) { ["http://www.example.com/test.jpg"] }

        it { is_expected.to match(/test.jpg$/) }

        it "marks the uploader as staged" do
          expect(instance.images[0].staged).to be true
        end
      end

      context "writes over a previously stored file" do
        subject { images[0].current_path }

        let(:remote_images_url) { ["http://www.example.com/test.jpg"] }

        before do
          instance.images = [stub_file("portrait.jpg")]
          instance.store_images!
          instance.remote_images_urls = remote_images_url
        end

        it { is_expected.to match(/test.jpg$/) }
      end

      context "does not write over a previously assigned file" do
        subject { images[0].current_path }

        let(:remote_images_url) { ["http://www.example.com/test.jpg"] }

        before do
          instance.images = [stub_file("portrait.jpg")]
          instance.remote_images_urls = remote_images_url
        end

        it { is_expected.to match(/portrait.jpg$/) }
      end
    end

    describe '#store_images!' do
      before do
        allow(instance).to receive(:write_uploader)
        allow(instance).to receive(:read_uploader).and_return(nil)
      end

      context "does nothing when no file has been uploaded" do
        before { instance.store_images! }

        it { expect(instance.images).to be_empty }
      end

      context "stores an assigned file" do
        let(:images) { [test_file_stub] }

        before do
          instance.images = images
          instance.store_images!
        end

        it { expect(instance.images[0].current_path).to eq(public_path("uploads/#{test_file_name}")) }

        it "marks the uploader as unstaged" do
          expect(instance.images[0].staged).to be false
        end
      end

      context "removes an uploaded file when remove_images is true" do
        let(:images) { [test_file_stub] }

        before do
          instance.images = images
          @image_path = instance.images[0].current_path.dup
          instance.remove_images = true
          instance.store_images!
        end

        it { expect(instance.images).to be_empty }

        it { expect(File.exist?(@image_path)).to be_falsey }
      end
    end

    describe '#remove_images!' do
      before do
        allow(instance).to receive(:write_uploader)
        allow(instance).to receive(:read_uploader).and_return(nil)
      end

      context "does nothing when no file has been uploaded" do
        before { instance.remove_images! }

        it { expect(instance.images).to be_empty }
      end

      context "removes an uploaded file" do
        before do
          instance.images = [test_file_stub]
          @image_path = instance.images[0].current_path
          instance.remove_images!
        end

        it { expect(instance.images).to be_empty }

        it { expect(File.exist?(@image_path)).to be_falsey }
      end
    end

    describe '#remove_images' do
      before { instance.remove_images = true }

      it "stores a value" do
        expect(instance.remove_images).to be_truthy
      end
    end

    describe '#remove_images?' do
      subject { instance.remove_images? }

      let(:remove_images) { true }

      before { instance.remove_images = remove_images }

      it "when value is true" do
        is_expected.to be_truthy
      end

      context "when value is false" do
        let(:remove_images) { false }

        it { is_expected.to be_falsey }
      end

      context "when value is ''" do
        let(:remove_images) { '' }

        it { is_expected.to be_falsey }
      end

      context "when value is 0" do
        let(:remove_images) { "0" }

        it { is_expected.to be_falsey }
      end

      context "when value is false" do
        let(:remove_images) { 'false' }

        it { is_expected.to be_falsey }
      end
    end

    describe '#images_integrity_error' do
      subject(:images_integrity_error) { instance.images_integrity_error }

      describe "default behaviour" do
        it { is_expected.to be_nil }
      end

      context "when a file is cached" do
        before { instance.images = test_file_stub }

        it { is_expected.to be_nil }
      end

      describe "when an integrity check fails" do
        before do
          uploader.class_eval do
            def extension_whitelist
              %w(txt)
            end
          end
        end

        context "when file is cached" do
          before { instance.images = [test_file_stub] }

          it { is_expected.to be_an_instance_of(CarrierWave::IntegrityError) }

          it "has an error message" do
            expect(images_integrity_error.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
          end
        end

        context "when file was downloaded" do
          before do
            stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: File.read(test_file_stub))
            instance.remote_images_urls = ["http://www.example.com/#{test_file_name}"]
          end

          it { is_expected.to be_an_instance_of(CarrierWave::IntegrityError) }

          it "has an error message" do
            expect(images_integrity_error.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
          end
        end

        context "when file is assigned and remote_iamges_url is blank" do
          before do
            instance.images = [test_file_stub]
            instance.remote_images_urls = ""
          end

          it { is_expected.to be_an_instance_of(CarrierWave::IntegrityError) }

          it "has an error message" do
            expect(images_integrity_error.message.lines.grep(/^You are not allowed to upload/)).to be_truthy
          end
        end
      end
    end

    describe '#images_processing_error' do
      subject(:images_processing_error) { instance.images_processing_error }

      describe "default behavior" do
        it { is_expected.to be_nil }
      end

      context "when file is cached" do
        before { instance.images = [test_file_stub] }

        it { is_expected.to be_nil }
      end

      describe "when an processing error occurs" do
        before do
          uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError, "Ohh noez!"
            end
          end
        end

        context "when file is cached" do
          before { instance.images = [test_file_stub] }

          it { is_expected.to be_an_instance_of(CarrierWave::ProcessingError) }
        end

        context "when file was downloaded" do
          before do
            stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: File.read(test_file_stub))
            instance.remote_images_urls = ["http://www.example.com/#{test_file_name}"]
          end

          it { is_expected.to be_an_instance_of(CarrierWave::ProcessingError) }
        end
      end
    end

    describe '#images_download_error' do
      subject(:images_download_error) { instance.images_download_error }

      before do
        stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: File.read(test_file_stub))
        stub_request(:get, "www.example.com/missing.jpg").to_return(status: 404)
      end

      describe "default behaviour" do
        it { expect(instance.images_download_error).to be_nil }
      end

      context "when file download was successful" do
        before { instance.remote_images_urls = ["http://www.example.com/#{test_file_name}"] }

        it { is_expected.to be_nil }
      end

      context "when file couldn't be found" do
        before { instance.remote_images_urls = ["http://www.example.com/missing.jpg"] }

        it { is_expected.to be_an_instance_of(CarrierWave::DownloadError) }
      end
    end

    describe '#write_images_identifier' do
      after { instance.write_images_identifier }

      it "writes to the column" do
        expect(instance).to receive(:write_uploader).with(:images, [test_file_name]).at_least(:once)
        instance.images = [test_file_stub]
        instance.write_images_identifier
      end

      context "when remove_images is true" do
        before do
          instance.images = [test_file_name]
          instance.store_images!
          instance.remove_images = true
        end

        it "removes from the column when remove_images is true" do
          expect(instance).to receive(:write_uploader).with(:images, nil)
        end
      end
    end

    describe '#images_identifiers' do
      it "returns the identifier from the mounted column" do
        expect(instance).to receive(:read_uploader).with(:images).and_return(test_file_name)
        expect(instance.images_identifiers).to eq([test_file_name])
      end
    end
  end

  describe '#mount_uploaders without an uploader' do
    let(:klass) do
      Class.new.tap do |k|
        k.send(:extend, CarrierWave::Mount)
        k.mount_uploaders(:images)
      end
    end

    let(:instance) { klass.new }

    describe '#images' do
      before do
        allow(instance).to receive(:read_uploader).and_return(test_file_name)
      end

      it "returns an instance of a subclass of CarrierWave::Uploader::Base" do
        expect(instance.images[0]).to be_a(CarrierWave::Uploader::Base)
      end

      it "sets the path to the store dir" do
        expect(instance.images[0].current_path).to eq(public_path("uploads/#{test_file_name}"))
      end
    end
  end

  describe '#mount_uploaders with a block' do
    describe 'and no uploader given' do
      subject(:last_image) { instance.images[0] }

      let(:klass) do
        Class.new do |k|
          k.send(:extend, CarrierWave::Mount)
          k.mount_uploaders(:images) do
            def monkey
              'blah'
            end
          end
        end
      end

      before { instance.images = [test_file_stub] }

      it "returns an instance of a subclass of CarrierWave::Uploader::Base" do
        is_expected.to be_a(CarrierWave::Uploader::Base)
      end

      it "applies any custom modifications" do
        expect(last_image.monkey).to eq("blah")
      end
    end

    describe 'and an uploader given' do
      let!(:uploader) do
        Class.new(CarrierWave::Uploader::Base).tap do |u|
          u.version :thumb do
            version :mini
            version :maxi
          end
        end
      end

      let(:klass) do
        Class.new.tap do |k|
          k.send(:extend, CarrierWave::Mount)
          k.mount_uploaders(:images, uploader) do
            def fish
              'blub'
            end
          end
        end
      end

      let(:first_image) { instance.images[0] }

      before { instance.images = [test_file_stub] }

      it "returns an instance of the uploader specified" do
        expect(first_image).to be_a_kind_of(uploader)
      end

      it "applies any custom modifications to the instance" do
        expect(first_image.fish).to eq("blub")
      end

      it "applies any custom modifications to all defined versions" do
        expect(first_image.thumb.fish).to eq("blub")
        expect(first_image.thumb.mini.fish).to eq("blub")
        expect(first_image.thumb.maxi.fish).to eq("blub")
      end

      it "applies any custom modifications to the uploader class" do
        expect(uploader.new).not_to respond_to(:fish)
      end
    end
  end

  describe '#mount_uploaders with :ignore_integrity_errors => false' do
    let(:klass) do
      Class.new.tap do |k|
        k.send(:extend, CarrierWave::Mount)
        k.mount_uploaders(:images, uploader, :ignore_integrity_errors => false)
      end
    end

    let(:uploader) do
      Class.new(CarrierWave::Uploader::Base).tap do |u|
        u.class_eval do
          def extension_whitelist
            %w(txt)
          end
        end
      end
    end

    context "when a cached image fails an integrity check" do
      it { expect(running { instance.images = [test_file_stub] }).to raise_error(CarrierWave::IntegrityError) }
    end

    context "when a downloaded image fails an integity check" do
      before do
        stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: test_file_stub)
      end

      it { expect(running {instance.remote_images_urls = ["http://www.example.com/#{test_file_name}"]}).to raise_error(CarrierWave::IntegrityError) }
    end
  end

  describe '#mount_uploaders with :ignore_processing_errors => false' do
    let(:klass) do
      Class.new.tap do |k|
        k.send(:extend, CarrierWave::Mount)
        k.mount_uploaders(:images, uploader, :ignore_processing_errors => false)
      end
    end

    let(:uploader) do
      Class.new(CarrierWave::Uploader::Base).tap do |u|
        u.class_eval do
          process :monkey
          def monkey
            raise CarrierWave::ProcessingError, "Ohh noez!"
          end
        end
      end
    end

    context "when a cached image fails an integrity check" do
      it { expect(running { instance.images = [test_file_stub] }).to raise_error(CarrierWave::ProcessingError) }
    end

    context "when a downloaded image fails an integity check" do
      before do
        stub_request(:get, "www.example.com/#{test_file_name}").to_return(body: test_file_stub)
      end

      it { expect(running {instance.remote_images_urls = ["http://www.example.com/#{test_file_name}"]}).to raise_error(CarrierWave::ProcessingError) }
    end
  end

  describe '#mount_uploaders with :ignore_download_errors => false' do
    let(:klass) do
      Class.new.tap do |k|
        k.send(:extend, CarrierWave::Mount)
        k.mount_uploaders(:images, uploader, ignore_download_errors: false)
      end
    end

    let(:uploader) { Class.new(CarrierWave::Uploader::Base) }

    before do
      uploader.class_eval do
        def download! uri, headers = {}
          raise CarrierWave::DownloadError
        end
      end
    end

    context "when the image fail to be processed" do
      it { expect(running {instance.remote_images_urls = ["http://www.example.com/#{test_file_name}"]}).to raise_error(CarrierWave::DownloadError) }
    end
  end

  describe '#mount_uploaders with :mount_on => :monkey' do
    let(:klass) do
      Class.new.tap do |k|
        k.send(:extend, CarrierWave::Mount)
        k.mount_uploaders(:images, uploader, mount_on: :monkey)
      end
    end

    let(:uploader) { Class.new(CarrierWave::Uploader::Base) }

    describe '#images' do
      context "when a value is store in the database" do
        it "retrieves a file from the storage" do
          expect(instance).to receive(:read_uploader).at_least(:once).with(:monkey).and_return([test_file_name])
          expect(instance.images[0]).to be_an_instance_of(uploader)
          expect(instance.images[0].current_path).to eq(public_path("uploads/#{test_file_name}"))
        end
      end
    end

    describe '#write_images_identifier' do
      it "writes to the given column" do
        expect(instance).to receive(:write_uploader).with(:monkey, [test_file_name])
        instance.images = [test_file_stub]
        instance.write_images_identifier
      end

      it "removes from the given column when remove_images is true" do
        instance.images = [test_file_stub]
        instance.store_images!
        instance.remove_images = true
        expect(instance).to receive(:write_uploader).with(:monkey, nil)
        instance.write_images_identifier
      end
    end
  end
end
