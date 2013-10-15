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
      pending 'This spec is deprecated because Proxy now read content type itself.'
      @instance.file.content_type = nil
      @instance.file.should_receive(:content_type=).with('image/jpeg')
      @instance.set_content_type
    end

    it "set content_type if content_type is empty" do
      @instance.file.content_type = ''
      @instance.file.should_receive(:content_type=).with('image/jpeg')
      @instance.set_content_type
    end

    %w[ application/octet-stream binary/octet-stream ].each do |type|
      it "sets content_type if content_type is generic (#{type})" do
        @instance.file.content_type = type
        @instance.file.should_receive(:content_type=).with('image/jpeg')
        @instance.set_content_type
      end
    end

    it "sets content_type if override is true" do
      @instance.file.content_type = 'image/jpeg'
      @instance.file.should_receive(:content_type=).with('image/jpeg')
      @instance.set_content_type(true)
    end

  end

  describe "test errors" do
    context "invalid mime type" do
      before do
        @instance.file.content_type = nil
        # TODO: somehow force a ::MIME::InvalidContentType error when set_content_type is called.
      end

      it "should raise a MIME::InvalidContentType error" do
        # lambda {@instance.set_content_type}.should raise_exception(::MIME::InvalidContentType, /^Failed to process file with MIME::Types, maybe not valid content-type\? Original Error:/)
      end
    end
  end
end
