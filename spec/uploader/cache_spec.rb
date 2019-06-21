require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:test_file_name) { "test.jpg"}
  let(:test_file_path) { file_path(test_file_name) }
  let(:test_file) { File.open(test_file_path) }
  let(:permission) { 0777 }
  let(:cache_id) { '1369894322-345-1234-2255' }

  before { FileUtils.rm_rf(public_path) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache_dir' do
    it "defaults to the config option" do
      expect(uploader.cache_dir).to eq('uploads/tmp')
    end
  end

  context "permissions" do
    it "sets permissions if options are given" do
      uploader_class.permissions = permission
      uploader.cache!(test_file)

      expect(uploader).to have_permissions(permission)
    end

    it "sets directory permissions if options are given" do
      uploader_class.directory_permissions = permission
      uploader.cache!(test_file)

      expect(uploader).to have_directory_permissions(permission)
    end

    describe "with ensuring multipart form deactivated" do
      before do
        CarrierWave.configure { |config| config.ensure_multipart_form = false }
      end

      it "doesn't raise an error when trying to cache a string" do
        expect(running {
                 uploader.cache!(file_path(test_file_name))
        }).not_to raise_error
      end

      it "doesn't raise an error when trying to cache a pathname and " do
        expect(running {
                 uploader.cache!(Pathname.new(file_path(test_file_name)))
        }).not_to raise_error
      end
    end
  end

  describe '#cache!' do
    before { allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id) }

    context "when ensure_multipart_form is true" do
      before { CarrierWave.configure { |config| config.ensure_multipart_form = true } }

      it "raises an error when trying to cache a string" do
        expect(running { uploader.cache!(test_file_path) }).to raise_error(CarrierWave::FormNotMultipart)
      end

      it "raises an error when trying to cache a pathname" do
        expect { uploader.cache!(Pathname.new(test_file)) }.to raise_error(CarrierWave::FormNotMultipart)
      end
    end

    context "when a file is cached" do
      before { uploader.cache!(test_file) }

      it "caches the file" do
        expect(uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
      end

      it { expect(uploader).to be_cached }

      it "stores the cache name" do
        expect(uploader.cache_name).to eq("#{cache_id}/#{test_file_name}")
      end

      it "sets the filename to the file's sanitized filename" do
        expect(uploader.filename).to eq(test_file_name)
      end

      it "moves it to the tmp dir" do
        expect(uploader.file.path).to eq(public_path("uploads/tmp/#{cache_id}/#{test_file_name}"))
      end

      it { expect(uploader.file.exists?).to be_truthy }

      it "sets the url" do
        expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
      end

      it "does nothing when trying to cache an empty file" do
        uploader.cache!(nil)
      end

      it "does not read whole content of file into memory" do
        expect(uploader.file).not_to receive(:read)
        uploader.cache!
      end

      context 'negative cache id' do
        let(:cache_id) { '-1369894322-345-1234-2255' }

        before do
          allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id)
        end

        it "doesn't raise an error when caching" do
          expect(running {
                   uploader.cache!(test_file)
          }).not_to raise_error
        end
      end
    end

    describe "with the move_to_cache option" do
      let(:tmp_file_name) { "test_move.jpeg" }
      let(:tmp_file_path) { file_path(tmp_file_name) }
      let(:tmp_file) { File.open(tmp_file_path) }
      let(:cached_id) { '1369894322-345-1234-2255' }
      let(:cached_path) { public_path("uploads/tmp/#{cached_id}/#{tmp_file_name}") }
      let(:workfile_path) { tmp_path("#{cached_id}/#{tmp_file_name}") }

      before do
        FileUtils.cp(test_file, File.join(File.dirname(test_file), tmp_file_name))

        allow(CarrierWave).to receive(:generate_cache_id).and_return(cached_id)

        uploader_class.permissions = permission
        uploader_class.directory_permissions = permission
      end

      after do
        FileUtils.rm_f(tmp_file.path)
      end

      context "set to true" do
        before { uploader_class.move_to_cache = true }

        context "moving from the upload directory to the temporary directory" do
          let(:original_path) { tmp_file.path }

          before { uploader.cache!(tmp_file) }

          it { expect(uploader.file.path).to eq(cached_path) }

          it { expect(File.exist?(cached_path)).to be_truthy }

          it { expect(File.exist?(original_path)).to be_falsey }

        end

        describe "method usage" do
          after { uploader.cache!(tmp_file) }

          it "uses #move_to during #cache!" do
            moved_file = double('moved file').as_null_object

            expect_any_instance_of(CarrierWave::SanitizedFile).to receive(:move_to).with(workfile_path, permission, permission).and_return(moved_file)
            expect(moved_file).to receive(:move_to).with(cached_path, permission, permission, true)
          end

          it "doesn't use #copy_to during #cache!" do
            expect_any_instance_of(CarrierWave::SanitizedFile).not_to receive(:copy_to)
          end
        end
      end

      context "set to false" do
        before { uploader_class.move_to_cache = false }

        context "copying from the upload directory to the temporary directory" do
          let(:original_path) { tmp_file.path }

          before { uploader.cache!(tmp_file) }

          it { expect(uploader.file.path).to eq(cached_path) }
          it { expect(File.exist?(cached_path)).to be_truthy }
          it { expect(File.exist?(original_path)).to be_truthy }
        end

        describe "method usage" do
          after { uploader.cache!(tmp_file) }

          it "uses #move_to during cache!" do
            moved_file = double('moved file').as_null_object

            expect_any_instance_of(CarrierWave::SanitizedFile).to receive(:copy_to).with(workfile_path, permission, permission).and_return(moved_file)
            expect(moved_file).to receive(:move_to).with(cached_path, permission, permission, true)
          end

          it "doesn't use #move_to during #cache!" do
            expect_any_instance_of(CarrierWave::SanitizedFile).not_to receive(:move_to).with(workfile_path, permission, permission)
          end
        end
      end
    end

    it "uses different workfiles for different versions" do
      uploader_class.version(:small)
      uploader_class.version(:large)

      uploader.cache!(test_file)

      expect(uploader.small.send(:workfile_path)).not_to eq uploader.large.send(:workfile_path)
    end
  end

  describe '#retrieve_from_cache!' do
    before { uploader.retrieve_from_cache!("#{cache_id}/#{test_file_name}") }

    it "caches a file" do
      expect(uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it { expect(uploader).to be_cached }

    it "sets the path to the tmp dir" do
      expect(uploader.current_path).to eq(public_path("uploads/tmp/#{cache_id}/#{test_file_name}"))
    end

    it "overwrites a file that has already been cached" do
      uploader.retrieve_from_cache!("#{cache_id}/#{test_file_name}")
      uploader.retrieve_from_cache!("#{cache_id}/bork.txt")

      expect(uploader.current_path).to eq(public_path("uploads/tmp/#{cache_id}/bork.txt"))
    end

    it "stores the cache_name" do
      expect(uploader.cache_name).to eq("#{cache_id}/#{test_file_name}")
    end

    it "stores the filename" do
      expect(uploader.filename).to eq(test_file_name)
    end

    it "sets the url" do
      expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
    end


    it "supports old format of cache_id (without counter) for backwards compartibility" do
      expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
    end

    it "raises an error when the cache_id has an invalid format" do
      expect(running {
        uploader.retrieve_from_cache!("12345/#{test_file_name}")
      }).to raise_error(CarrierWave::InvalidParameter)
    end

    context "when the original filename has invalid characters" do
      it do
        expect(running {
          uploader.retrieve_from_cache!('1369894322-345-1234-2255/te/st.jpeg')
        }).to raise_error(CarrierWave::InvalidParameter)
      end

      it do
        expect(running {
          uploader.retrieve_from_cache!('1369894322-345-1234-2255/te??%st.jpeg')
        }).to raise_error(CarrierWave::InvalidParameter)
      end
    end
  end

  describe 'with an overridden, reversing, filename' do
    before do
      uploader_class.class_eval do
        def filename
          super.reverse unless super.blank?
        end
      end

      allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id)
      uploader.cache!(test_file)
    end

    let(:reversed_test_file_name) { test_file_name.reverse }

    describe '#cache!' do
      it "sets the filename to the file's reversed filename" do
        expect(uploader.filename).to eq(reversed_test_file_name)
      end

      it "moves it to the tmp dir with the filename unreversed" do
        expect(uploader.current_path).to eq(public_path("uploads/tmp/#{cache_id}/#{test_file_name}"))
        expect(uploader.file.exists?).to be_truthy
      end
    end

    describe '#retrieve_from_cache!' do
      it "sets the path to the tmp dir" do
        expect(uploader.current_path).to eq(public_path("uploads/tmp/#{cache_id}/#{test_file_name}"))
      end

      it "sets the filename to the reversed name of the file" do
        expect(uploader.filename).to eq(reversed_test_file_name)
      end
    end
  end

  describe '.generate_cache_id' do
    it 'generates dir name based on UTC time' do
      Timecop.freeze(Time.at(1369896000)) do
        expect(CarrierWave.generate_cache_id).to match(/\A1369896000-\d+-\d+-\d+\Z/)
      end
    end

    it 'generates dir name with a counter substring' do
      counter = CarrierWave.generate_cache_id.split('-')[2].to_i

      expect(CarrierWave.generate_cache_id.split('-')[2].to_i).to eq(counter + 1)
    end

    it 'generates dir name with constant length even when counter has big value' do
      length = CarrierWave.generate_cache_id.length
      allow(CarrierWave::CacheCounter).to receive(:increment).and_return(1234567890)

      expect(CarrierWave.generate_cache_id.length).to eq(length)
    end
  end
end
