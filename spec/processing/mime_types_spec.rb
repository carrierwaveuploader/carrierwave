# encoding: utf-8

require 'spec_helper'

describe CarrierWave::MimeTypes do

  before do
    @klass = Class.new do
      attr_accessor :content_type
      include CarrierWave::MimeTypes
    end
    @instance = @klass.new
    FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
    @instance.stub(:original_filename).and_return file_path('landscape_copy.jpg')
    @instance.stub(:file).and_return CarrierWave::SanitizedFile.new(file_path('landscape_copy.jpg'))
    @file = @instance.file
  end

  after do
    FileUtils.rm(file_path('landscape_copy.jpg'))
  end

  describe '#set_content_type' do

    it "does not set content_type if already set" do
      @instance.file.content_type = 'image/jpeg'
      @instance.file.should_not_receive(:content_type=)
      @instance.set_content_type
    end

    it "set content_type if content_type is nil" do
      @instance.file.content_type = nil
      @instance.file.should_receive(:content_type=).with('image/jpeg')
      @instance.set_content_type
    end

    it "sets content_type if content_type is generic" do
      @instance.file.content_type = 'application/octet-stream'
      @instance.file.should_receive(:content_type=).with('image/jpeg')
      @instance.set_content_type
    end

    it "sets content_type if override is true" do
      @instance.file.content_type = 'image/jpeg'
      @instance.file.should_receive(:content_type=).with('image/jpeg')
      @instance.set_content_type(true)
    end

  end

end
