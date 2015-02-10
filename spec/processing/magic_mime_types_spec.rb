# encoding: utf-8

require 'spec_helper'

describe CarrierWave::MagicMimeTypes do

  before do
    @klass = Class.new(CarrierWave::Uploader::Base) do
      attr_accessor :content_type
      include CarrierWave::MagicMimeTypes
    end
    @instance = @klass.new
    FileUtils.cp(file_path('ruby.gif'), file_path('ruby_copy.gif'))
    @instance.stub(:original_filename).and_return file_path('ruby_copy.gif')
    @instance.stub(:file).and_return CarrierWave::SanitizedFile.new(file_path('ruby_copy.gif'))
    @file = @instance.file
  end

  after do
    FileUtils.rm(file_path('ruby_copy.gif'))
  end

  describe "#set_content_type" do
    it "does not set the content_type if already set" do
      @instance.file.content_type = 'image/jpeg'
      @instance.file.should_not_receive(:content_type=)
      @instance.set_content_type
    end

    it "sets content_type if content_type is nil" do
      pending
      @instance.file.content_type = nil
      @instance.file.should_receive(:content_type=).with('image/png')
      @instance.set_content_type
    end

    it "sets content_type if content_type is blank" do
      @instance.file.content_type = ''
      @instance.file.should_receive(:content_type=).with('image/png')
      @instance.set_content_type
    end

    it "sets content_type if override is true" do
      @instance.file.content_type = 'image/png'
      @instance.file.should_receive(:content_type=).with('image/png')
      @instance.set_content_type(true)
    end
  end
end
