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
    before { pending "Fails in JRuby with 'undefined local variable or method __memoized...'" if RUBY_ENGINE == 'jruby' }
    context "when FileUtils.mkdir_p raises Errno::EMLINK" do
      before { fake_failed_mkdir_p(Errno::EMLINK) }
      after { storage.cache!(sanitized_temp_file) }

      it { is_expected.to receive(:clean_cache!).with(600) }
    end

    context "when FileUtils.mkdir_p raises Errno::ENOSPC" do
      before { fake_failed_mkdir_p(Errno::ENOSPC) }
      after { storage.cache!(sanitized_temp_file) }

      it { is_expected.to receive(:clean_cache!).with(600) }
    end
  end

  describe '#clean_cache!' do
    let(:today) { '2016/10/09 10:00:00'.to_time }
    let(:five_days_ago) { today.ago(5.days) }
    let(:three_days_ago) { today.ago(3.days) }
    let(:yesterday) { today.yesterday }
    let(:cache_dir) { File.expand_path(uploader_class.cache_dir, CarrierWave.root) }

    before do
      [five_days_ago, three_days_ago, yesterday, (today - 1.minute)].each do |created_date|
        Timecop.freeze (created_date) do
          FileUtils.mkdir_p File.expand_path(CarrierWave.generate_cache_id, cache_dir)
        end
      end
    end

    after { FileUtils.rm_rf(cache_dir) }

    it "clears all files older than now in the default cache directory" do
      Timecop.freeze(today) { uploader_class.clean_cached_files!(0) }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(0)
    end

    it "clears all files older than, by default, 24 hours in the default cache directory" do
      Timecop.freeze(today) { uploader_class.clean_cached_files! }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(2)
    end

    it "allows to set since how many seconds delete the cached files" do
      Timecop.freeze(today) { uploader_class.clean_cached_files!(4.days) }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(3)
    end

    it "'s aliased on the CarrierWave module" do
      Timecop.freeze(today) { CarrierWave.clean_cached_files! }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(2)
    end

    it "cleans a directory named using old format of cache id" do
      FileUtils.mkdir_p File.expand_path("#{yesterday.utc.to_i}-100-1234", cache_dir)
      Timecop.freeze(today) { uploader_class.clean_cached_files!(0) }

      expect(Dir.glob("#{cache_dir}/*").size).to eq(0)
    end
  end
end
