# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '.process' do
    it "should add a single processor when a symbol is given" do
      @uploader_class.process :sepiatone
      expect(@uploader).to receive(:sepiatone)
      @uploader.process!
    end

    it "should add multiple processors when an array of symbols is given" do
      @uploader_class.process :sepiatone, :desaturate, :invert
      expect(@uploader).to receive(:sepiatone)
      expect(@uploader).to receive(:desaturate)
      expect(@uploader).to receive(:invert)
      @uploader.process!
    end

    it "should add a single processor with an argument when a hash is given" do
      @uploader_class.process :format => 'png'
      expect(@uploader).to receive(:format).with('png')
      @uploader.process!
    end

    it "should add a single processor with several argument when a hash is given" do
      @uploader_class.process :resize => [200, 300]
      expect(@uploader).to receive(:resize).with(200, 300)
      @uploader.process!
    end

    it "should add multiple processors when an hash with multiple keys is given" do
      @uploader_class.process :resize => [200, 300], :format => 'png'
      expect(@uploader).to receive(:resize).with(200, 300)
      expect(@uploader).to receive(:format).with('png')
      @uploader.process!
    end

    it "should call the processor if the condition method returns true" do
      @uploader_class.process :resize => [200, 300], :if => :true?
      @uploader_class.process :fancy, :if => :true?
      expect(@uploader).to receive(:true?).with("test.jpg").twice.and_return(true)
      expect(@uploader).to receive(:resize).with(200, 300)
      expect(@uploader).to receive(:fancy)
      @uploader.process!("test.jpg")
    end

    it "should not call the processor if the condition method returns false" do
      @uploader_class.process :resize => [200, 300], :if => :false?
      @uploader_class.process :fancy, :if => :false?
      expect(@uploader).to receive(:false?).with("test.jpg").twice.and_return(false)
      expect(@uploader).not_to receive(:resize)
      expect(@uploader).not_to receive(:fancy)
      @uploader.process!("test.jpg")
    end

    it "should call the processor if the condition block returns true" do
      @uploader_class.process :resize => [200, 300], :if => lambda{|record, args| record.true?(args[:file])}
      @uploader_class.process :fancy, :if => :true?
      expect(@uploader).to receive(:true?).with("test.jpg").twice.and_return(true)
      expect(@uploader).to receive(:resize).with(200, 300)
      expect(@uploader).to receive(:fancy)
      @uploader.process!("test.jpg")
    end

    it "should not call the processor if the condition block returns false" do
      @uploader_class.process :resize => [200, 300], :if => lambda{|record, args| record.false?(args[:file])}
      @uploader_class.process :fancy, :if => :false?
      expect(@uploader).to receive(:false?).with("test.jpg").twice.and_return(false)
      expect(@uploader).not_to receive(:resize)
      expect(@uploader).not_to receive(:fancy)
      @uploader.process!("test.jpg")
    end

    context "when using RMagick", :rmagick => true do
      before do
        def @uploader.cover
          manipulate! { |frame, index| frame if index.zero? }
        end

        @uploader_class.send :include, CarrierWave::RMagick
      end

      after do
        @uploader.instance_eval { undef cover }
      end

      context "with a multi-page PDF" do
        before do
          @uploader.cache! File.open(file_path("multi_page.pdf"))
        end

        it "should successfully process" do
          @uploader_class.process :convert => 'jpg'
          @uploader.process!
        end

        it "should support page specific transformations" do
          @uploader_class.process :cover
          @uploader.process!
        end
      end

      context "with a simple image" do
        before do
          @uploader.cache! File.open(file_path("portrait.jpg"))
        end

        it "should still allow page specific transformations" do
          @uploader_class.process :cover
          @uploader.process!
        end
      end
    end

    context "with 'enable_processing' set to false" do
      it "should not do any processing" do
        @uploader_class.enable_processing = false
        @uploader_class.process :sepiatone, :desaturate, :invert
        expect(@uploader).not_to receive(:sepiatone)
        expect(@uploader).not_to receive(:desaturate)
        expect(@uploader).not_to receive(:invert)
        @uploader.process!
      end
    end
  end

  describe '#cache!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "should trigger a process!" do
      expect(@uploader).to receive(:process!)
      @uploader.cache!(File.open(file_path('test.jpg')))
    end
  end

  describe '#recreate_versions!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "should trigger a process!" do
      @uploader.store!(File.open(file_path('test.jpg')))
      expect(@uploader).to receive(:process!)
      @uploader.recreate_versions!
    end
  end

end
