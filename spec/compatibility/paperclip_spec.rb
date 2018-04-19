require 'spec_helper'
require 'carrierwave/orm/activerecord'

module Rails; end unless defined?(Rails)

describe CarrierWave::Compatibility::Paperclip do
  let(:uploader_class) do
    Class.new(CarrierWave::Uploader::Base) do
      include CarrierWave::Compatibility::Paperclip

      version :thumb
      version :list
    end
  end

  let(:model) { double('model') }

  let(:uploader) { uploader_class.new(model, :monkey) }

  before do
    allow(Rails).to receive(:root).and_return('/rails/root')
    allow(Rails).to receive(:env).and_return('test')
    allow(model).to receive(:id).and_return(23)
    allow(model).to receive(:ook).and_return('eek')
    allow(model).to receive(:money).and_return('monkey.png')
  end

  after { FileUtils.rm_rf(public_path) }

  describe '#store_path' do
    subject { uploader.store_path("monkey.png") }

    it "mimics paperclip default" do
      is_expected.to eq("/rails/root/public/system/monkeys/23/original/monkey.png")
    end

    it "interpolates the root path" do
      allow(uploader).to receive(:paperclip_path).and_return(":rails_root/foo/bar")
      is_expected.to eq(Rails.root + "/foo/bar")
    end

    it "interpolates the attachment" do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:attachment/bar")
      is_expected.to eq("/foo/monkeys/bar")
    end

    it "interpolates the id" do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:id/bar")
      is_expected.to eq("/foo/23/bar")
    end

    it "interpolates the id partition" do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:id_partition/bar")
      is_expected.to eq("/foo/000/000/023/bar")
    end

    it "interpolates the basename" do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:basename/bar")
      is_expected.to eq("/foo/monkey/bar")
    end

    it "interpolates the extension" do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:extension/bar")
      is_expected.to eq("/foo/png/bar")
    end
  end

  describe '.interpolate' do
    subject { uploader.store_path("monkey.png") }

    before do
      uploader_class.interpolate :ook do |custom, style|
        custom.model.ook
      end

      uploader_class.interpolate :aak do |model, style|
        style
      end
    end

    it 'allows you to add custom interpolations' do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:id/:ook")
      is_expected.to eq('/foo/23/eek')
    end

    it 'mimics paperclips arguments' do
      allow(uploader).to receive(:paperclip_path).and_return("/foo/:aak")
      is_expected.to eq('/foo/original')
    end

    context 'when multiple uploaders include the compatibility module' do
      let(:uploader) { uploader_class_other.new(model, :monkey) }
      let(:uploader_class_other) do
        Class.new(CarrierWave::Uploader::Base) do
          include CarrierWave::Compatibility::Paperclip

          version :thumb
          version :list
        end
      end

      before { allow(uploader).to receive(:paperclip_path).and_return("/foo/:id/:ook") }

      it "doesn't share custom interpolations" do
        is_expected.to eq('/foo/23/:ook')
      end
    end

    context 'when there are multiple versions' do
      let(:complex_uploader_class) do
        Class.new(CarrierWave::Uploader::Base) do
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
      end

      let(:uploader) { complex_uploader_class.new(model, :monkey) }
      let!(:file) { File.open(file_path('test.jpg')) }

      before { uploader.store!(file) }

      it 'interpolates for all versions correctly' do
        expect(uploader.thumb.path).to eq("#{public_path}/foo/eek/23/thumb")
        expect(uploader.list.path).to eq("#{public_path}/foo/eek/23/list")
      end
    end
  end
end
