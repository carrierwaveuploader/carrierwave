# encoding: utf-8

require 'spec_helper'

require 'carrierwave/orm/activerecord'

module Rails; end unless defined?(Rails)

describe CarrierWave::Compatibility::Paperclip do

  before do
    allow(Rails).to receive(:root).and_return('/rails/root')
    allow(Rails).to receive(:env).and_return('test')
    @uploader_class = Class.new(CarrierWave::Uploader::Base) do
      include CarrierWave::Compatibility::Paperclip

      version :thumb
      version :list

    end

    @model = double('a model')
    allow(@model).to receive(:id).and_return(23)
    allow(@model).to receive(:ook).and_return('eek')
    allow(@model).to receive(:money).and_return('monkey.png')

    @uploader = @uploader_class.new(@model, :monkey)
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#store_path' do
    it "should mimics paperclip default" do
      expect(@uploader.store_path("monkey.png")).to eq("/rails/root/public/system/monkeys/23/original/monkey.png")
    end

    it "should interpolate the root path" do
      allow(@uploader).to receive(:paperclip_path).and_return(":rails_root/foo/bar")
      expect(@uploader.store_path("monkey.png")).to eq(Rails.root + "/foo/bar")
    end

    it "should interpolate the attachment" do
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:attachment/bar")
      expect(@uploader.store_path("monkey.png")).to eq("/foo/monkeys/bar")
    end

    it "should interpolate the id" do
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:id/bar")
      expect(@uploader.store_path("monkey.png")).to eq("/foo/23/bar")
    end

    it "should interpolate the id partition" do
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:id_partition/bar")
      expect(@uploader.store_path("monkey.png")).to eq("/foo/000/000/023/bar")
    end

    it "should interpolate the basename" do
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:basename/bar")
      expect(@uploader.store_path("monkey.png")).to eq("/foo/monkey/bar")
    end

    it "should interpolate the extension" do
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:extension/bar")
      expect(@uploader.store_path("monkey.png")).to eq("/foo/png/bar")
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
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:id/:ook")
      expect(@uploader.store_path("monkey.png")).to eq('/foo/23/eek')
    end

    it 'mimics paperclips arguments' do
      allow(@uploader).to receive(:paperclip_path).and_return("/foo/:aak")
      expect(@uploader.store_path("monkey.png")).to eq('/foo/original')
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
        allow(@uploader).to receive(:paperclip_path).and_return("/foo/:id/:ook")
        expect(@uploader.store_path('monkey.jpg')).to eq('/foo/23/:ook')
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
        expect(@uploader.thumb.path).to eq("#{public_path}/foo/eek/23/thumb")
        expect(@uploader.list.path).to eq("#{public_path}/foo/eek/23/list")
      end
    end
  end
end
