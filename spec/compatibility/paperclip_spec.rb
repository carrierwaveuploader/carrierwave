# encoding: utf-8

require 'spec_helper'

require 'carrierwave/orm/activerecord'

module Rails; end unless defined?(Rails)

describe CarrierWave::Compatibility::Paperclip do

  before do
    Rails.stub(:root).and_return('/rails/root')
    Rails.stub(:env).and_return('test')
    @uploader_class = Class.new(CarrierWave::Uploader::Base) do
      include CarrierWave::Compatibility::Paperclip

      version :thumb
      version :list

    end

    @model = double('a model')
    @model.stub(:id).and_return(23)
    @model.stub(:ook).and_return('eek')
    @model.stub(:money).and_return('monkey.png')

    @uploader = @uploader_class.new(@model, :monkey)
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#store_path' do
    it "should mimics paperclip default" do
      @uploader.store_path("monkey.png").should == "/rails/root/public/system/monkeys/23/original/monkey.png"
    end

    it "should interpolate the root path" do
      @uploader.stub(:paperclip_path).and_return(":rails_root/foo/bar")
      @uploader.store_path("monkey.png").should == Rails.root + "/foo/bar"
    end

    it "should interpolate the attachment" do
      @uploader.stub(:paperclip_path).and_return("/foo/:attachment/bar")
      @uploader.store_path("monkey.png").should == "/foo/monkeys/bar"
    end

    it "should interpolate the id" do
      @uploader.stub(:paperclip_path).and_return("/foo/:id/bar")
      @uploader.store_path("monkey.png").should == "/foo/23/bar"
    end

    it "should interpolate the id partition" do
      @uploader.stub(:paperclip_path).and_return("/foo/:id_partition/bar")
      @uploader.store_path("monkey.png").should == "/foo/000/000/023/bar"
    end

    it "should interpolate the basename" do
      @uploader.stub(:paperclip_path).and_return("/foo/:basename/bar")
      @uploader.store_path("monkey.png").should == "/foo/monkey/bar"
    end

    it "should interpolate the extension" do
      @uploader.stub(:paperclip_path).and_return("/foo/:extension/bar")
      @uploader.store_path("monkey.png").should == "/foo/png/bar"
    end

  end

  describe '.interpolate' do
    before do
      @uploader_class.interpolate :ook do |custom, style|
        custom.model.ook
      end


      @uploader_class.interpolate :aak do |model, style|
        style
      end
    end

    it 'should allow you to add custom interpolations' do
      @uploader.stub(:paperclip_path).and_return("/foo/:id/:ook")
      @uploader.store_path("monkey.png").should == '/foo/23/eek'
    end

    it 'mimics paperclips arguments' do
      @uploader.stub(:paperclip_path).and_return("/foo/:aak")
      @uploader.store_path("monkey.png").should == '/foo/original'
    end

    context 'when multiple uploaders include the compatibility module' do
      before do
        @uploader_class_other = Class.new(CarrierWave::Uploader::Base) do
          include CarrierWave::Compatibility::Paperclip

          version :thumb
          version :list
        end

        @uploader = @uploader_class_other.new(@model, :monkey)
      end

      it 'should not share custom interpolations' do
        @uploader.stub(:paperclip_path).and_return("/foo/:id/:ook")
        @uploader.store_path('monkey.jpg').should == '/foo/23/:ook'
      end

    end

    context 'when there are multiple versions' do
      before do
        @complex_uploader_class = Class.new(CarrierWave::Uploader::Base) do
          include CarrierWave::Compatibility::Paperclip

          interpolate :ook do |model, style|
            'eek'
          end

          version :thumb
          version :list

          def paperclip_path
            "#{public_path}/foo/:ook/:id/:style"
          end
        end

        @uploader = @complex_uploader_class.new(@model, :monkey)
      end

      it 'should interpolate for all versions correctly' do
        @file = File.open(file_path('test.jpg'))
        @uploader.store!(@file)
        @uploader.thumb.path.should == "#{public_path}/foo/eek/23/thumb"
        @uploader.list.path.should == "#{public_path}/foo/eek/23/list"
      end
    end
  end
end
