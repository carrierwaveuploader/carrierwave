# encoding: utf-8

require 'spec_helper'

describe CarrierWave::MagicMimeTypes do

  before do
    @klass = Class.new do
      attr_accessor :content_type
      include CarrierWave::MagicMimeTypes
    end
    @instance = @klass.new
    FileUtils.cp(file_path('sponsored.doc'), file_path('sponsored_copy.doc'))
    @instance.stub(:original_filename).and_return file_path('sponsored_copy.doc')
    @instance.stub(:file).and_return CarrierWave::SanitizedFile.new(file_path('sponsored_copy.doc'))
    @file = @instance.file
  end

  after do
    FileUtils.rm(file_path('sponsored_copy.doc'))
  end

  describe '#set_magic_content_type' do

    it "does not set content_type if already set" do
      @instance.file.content_type = 'text/plain'
      @instance.file.should_not_receive(:content_type=)
      @instance.set_magic_content_type
    end

    it "set content_type if content_type is nil" do
      @instance.file.content_type = nil
      @instance.file.should_receive(:content_type=).with('text/plain')
      @instance.set_magic_content_type
    end

    it "set content_type if content_type is empty" do
      @instance.file.content_type = ''
      @instance.file.should_receive(:content_type=).with('text/plain')
      @instance.set_magic_content_type
    end

    %w[ application/download application/save bad/type
        file/unknown unknown/application unknown/data ].each do |type|
      it "sets content_type if content_type is generic (#{type})" do
        @instance.file.content_type = type
        @instance.file.should_receive(:content_type=).with('text/plain')
        @instance.set_magic_content_type
      end
    end

    it "set content_type based on file content" do
      @instance.file.should_receive(:content_type=).with( 'text/plain' )
      @instance.set_magic_content_type
    end

    it "sets content_type if override is true" do
      @instance.file.content_type = 'image/jpeg'
      @instance.file.should_receive(:content_type=).with('text/plain')
      @instance.set_magic_content_type(true)
    end

  end

end
