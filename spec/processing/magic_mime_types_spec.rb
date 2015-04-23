# encoding: utf-8

require 'spec_helper'

describe CarrierWave::MagicMimeTypes, :filemagic => true do

  before do
    @klass = Class.new(CarrierWave::Uploader::Base) do
      attr_accessor :content_type
      include CarrierWave::MagicMimeTypes
    end
    @instance = @klass.new
    FileUtils.cp(file_path('ruby.gif'), file_path('ruby_copy.gif'))
    allow(@instance).to receive(:original_filename).and_return file_path('ruby_copy.gif')
    allow(@instance).to receive(:file).and_return CarrierWave::SanitizedFile.new(file_path('ruby_copy.gif'))
    @file = @instance.file
  end

  after do
    FileUtils.rm(file_path('ruby_copy.gif'))
  end

  describe "#set_content_type" do
    it "does not set the content_type if already set" do
      @instance.file.content_type = 'image/jpeg'
      expect(@instance.file).not_to receive(:content_type=)
      @instance.set_content_type
    end

    it "sets content_type if content_type is nil" do
      pending
      @instance.file.content_type = nil
      expect(@instance.file).to receive(:content_type=).with('image/png')
      @instance.set_content_type
    end

    it "sets content_type if content_type is blank" do
      @instance.file.content_type = ''
      expect(@instance.file).to receive(:content_type=).with('image/png')
      @instance.set_content_type
    end

    it "sets content_type if override is true" do
      @instance.file.content_type = 'image/png'
      expect(@instance.file).to receive(:content_type=).with('image/png')
      @instance.set_content_type(true)
    end
  end
end
