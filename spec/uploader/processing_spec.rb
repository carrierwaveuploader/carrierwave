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
      @uploader.should_receive(:sepiatone)
      @uploader.process!
    end

    it "should add multiple processors when an array of symbols is given" do
      @uploader_class.process :sepiatone, :desaturate, :invert
      @uploader.should_receive(:sepiatone)
      @uploader.should_receive(:desaturate)
      @uploader.should_receive(:invert)
      @uploader.process!
    end

    it "should add a single processor with an argument when a hash is given" do
      @uploader_class.process :format => 'png'
      @uploader.should_receive(:format).with('png')
      @uploader.process!
    end

    it "should add a single processor with several argument when a hash is given" do
      @uploader_class.process :resize => [200, 300]
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.process!
    end

    it "should add multiple processors when an hash with multiple keys is given" do
      @uploader_class.process :resize => [200, 300], :format => 'png'
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.should_receive(:format).with('png')
      @uploader.process!
    end

    it "should call the processor if the condition method returns true" do
      @uploader_class.process :resize => [200, 300], :if => :true?
      @uploader.should_receive(:true?).with("test.jpg").and_return(true)
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.process!("test.jpg")
    end

    it "should not call the processor if the condition method returns false" do
      @uploader_class.process :resize => [200, 300], :if => :false?
      @uploader.should_receive(:false?).with("test.jpg").and_return(false)
      @uploader.should_not_receive(:resize)
      @uploader.process!("test.jpg")
    end

    context "with 'enable_processing' set to false" do
      it "should not do any processing" do
        @uploader_class.enable_processing = false
        @uploader_class.process :sepiatone, :desaturate, :invert
        @uploader.should_not_receive(:sepiatone)
        @uploader.should_not_receive(:desaturate)
        @uploader.should_not_receive(:invert)
        @uploader.process!
      end
    end
  end

  describe '#cache!' do
    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should trigger a process!" do
      @uploader.should_receive(:process!)
      @uploader.cache!(File.open(file_path('test.jpg')))
    end
  end

  describe '#recreate_versions!' do
    before do
      CarrierWave.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end

    it "should trigger a process!" do
      @uploader.store!(File.open(file_path('test.jpg')))
      @uploader.should_receive(:process!)
      @uploader.recreate_versions!
    end
  end

end
