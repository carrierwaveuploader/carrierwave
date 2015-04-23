# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Storage::File do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#delete_dir!' do
    before do
      @file = File.open(file_path('test.jpg'))
    end

    context "when the directory is not empty" do
      before do
        @uploader.cache!(@file)
        cache_path = ::File.expand_path(File.join(@uploader.cache_dir, @uploader.cache_name), @uploader.root)
        @cache_id_dir = File.dirname(cache_path)
        @existing_file = File.join(@cache_id_dir, "exsting_file.txt")
        File.open(@existing_file, "wb"){|f| f << "I exist"}
      end

      it "should not delete the old cache_id" do
        @uploader.store!
        expect(File).to be_directory(@cache_id_dir)
      end

      it "should not delete other existing files in old cache_id dir" do
        @uploader.store!
        expect(File).to exist @existing_file
      end
    end
  end

  describe '#clean_cache!' do
    before do
      five_days_ago_int  = 1369894322
      three_days_ago_int = 1370067122
      yesterday_int      = 1370239922

      @cache_dir = File.expand_path(@uploader_class.cache_dir, CarrierWave.root)
      FileUtils.mkdir_p File.expand_path("#{five_days_ago_int}-234-2213", @cache_dir)
      FileUtils.mkdir_p File.expand_path("#{three_days_ago_int}-234-2213", @cache_dir)
      FileUtils.mkdir_p File.expand_path("#{yesterday_int}-234-2213", @cache_dir)
    end

    after { FileUtils.rm_rf(@cache_dir) }

    it "should clear all files older than, by default, 24 hours in the default cache directory" do
      Timecop.freeze(Time.at(1370261522)) do
        @uploader_class.clean_cached_files!
      end
      expect(Dir.glob("#{@cache_dir}/*").size).to eq(1)
    end

    it "should permit to set since how many seconds delete the cached files" do
      Timecop.freeze(Time.at(1370261522)) do
        @uploader_class.clean_cached_files!(60*60*24*4)
      end
      expect(Dir.glob("#{@cache_dir}/*").size).to eq(2)
    end

    it "should be aliased on the CarrierWave module" do
      Timecop.freeze(Time.at(1370261522)) do
        CarrierWave.clean_cached_files!
      end
      expect(Dir.glob("#{@cache_dir}/*").size).to eq(1)
    end
  end
end
