require 'spec_helper'
require 'support/file_utils_helper'
require 'tempfile'

describe CarrierWave::Storage::File do
  include FileUtilsHelper

  subject(:storage) { described_class.new(uploader) }

  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:tempfile) { Tempfile.new("foo") }
  let(:sanitized_temp_file) { CarrierWave::SanitizedFile.new(tempfile) }
  let(:uploader) { uploader_class.new }

  after { FileUtils.rm_rf(public_path) }

  describe '#delete_dir!' do
    let(:file) { File.open(file_path("test.jpg")) }

    context "when the directory is not empty" do
      let(:cache_id_dir) { File.dirname(cache_path) }
      let(:cache_path) { File.expand_path(File.join(uploader.cache_dir, uploader.cache_name), uploader.root) }
      let(:existing_file) { File.join(cache_id_dir, "exsting_file.txt") }

      before do
        uploader.cache!(file)
        File.open(existing_file, "wb"){|f| f << "I exist"}
        uploader.store!
      end

      it "doesn't delete the old cache_id" do
        expect(File).to be_directory(cache_id_dir)
      end

      it "doesn't delete other existing files in old cache_id dir" do
        expect(File).to exist existing_file
      end
    end
  end

  describe '#cache!' do
    context "when FileUtils.mkdir_p raises Errno::EMLINK" do
      before { fake_failed_mkdir_p }
      after { storage.cache!(sanitized_temp_file) }

      it { is_expected.to receive(:clean_cache!).with(600) }
    end
  end

  describe '#clean_cache!' do
    let(:five_days_ago_int) { 1369894322 }
    let(:three_days_ago_int) { 1370067122 }
    let(:yesterday_int) { 1370239922 }
    let(:cache_dir) { File.expand_path(uploader_class.cache_dir, CarrierWave.root) }

    before do
      FileUtils.mkdir_p File.expand_path("#{five_days_ago_int}-234-1234-2213", cache_dir)
      FileUtils.mkdir_p File.expand_path("#{three_days_ago_int}-234-1234-2213", cache_dir)
      FileUtils.mkdir_p File.expand_path("#{yesterday_int}-234-1234-2213", cache_dir)
    end

    after { FileUtils.rm_rf(cache_dir) }

    it "clears all files older than, by default, 24 hours in the default cache directory" do
      Timecop.freeze(Time.at(1370261522)) { uploader_class.clean_cached_files! }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(1)
    end

    it "allows to set since how many seconds delete the cached files" do
      Timecop.freeze(Time.at(1370261522)) { uploader_class.clean_cached_files!(60*60*24*4) }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(2)
    end

    it "'s aliased on the CarrierWave module" do
      Timecop.freeze(Time.at(1370261522)) { CarrierWave.clean_cached_files! }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(1)
    end
  end
end
