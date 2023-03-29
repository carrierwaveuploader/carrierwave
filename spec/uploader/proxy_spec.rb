require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:test_file_name) { 'test.jpg' }
  let(:test_file) { File.open(file_path(test_file_name)) }
  let(:path) { '1369894322-345-1234-2255/test.jpeg' }

  after { FileUtils.rm_rf(public_path) }

  describe '#blank?' do
    subject { uploader }

    context "when nothing has been done" do
      it { is_expected.to be_blank }
    end

    context "when file is empty" do
      before { uploader.retrieve_from_cache!(path) }

      it { is_expected.to be_blank }
    end

    context "when file has been cached" do
      before { uploader.cache!(test_file) }

      it { is_expected.not_to be_blank }
    end
  end

  describe '#identifier' do
    subject { uploader.identifier }

    context "when nothing has been done" do
      it { is_expected.to be_nil }
    end

    context "when a file is stored" do
      before { uploader.store!(test_file) }

      it { is_expected.to eq 'test.jpg' }
    end

    context "when #filename is set to always return a value" do
      before do
        uploader.class_eval do
          def filename
            'dummy'
          end
        end
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#read' do
    subject { uploader.read }

    describe "default behavior" do
      it { is_expected.to be nil }
    end

    context "when file is cached" do
      before { uploader.cache!(test_file) }

      it { is_expected.to eq("this is stuff") }
    end
  end

  describe '#size' do
    subject { uploader.size }

    describe "default behavior" do
      it { is_expected.to be 0 }
    end

    context "when file is cached" do
      before { uploader.cache!(test_file) }

      it { is_expected.to be 13 }
    end
  end

  describe '#content_type' do
    subject { uploader.content_type }

    context "when nothing has been done" do
      it { is_expected.to be_nil }
    end

    context "when the file has been cached" do
      let(:test_file_name) { 'landscape.jpg' }
      before { uploader.cache!(test_file) }

      it { is_expected.to eq('image/jpeg') }
    end

    context "when the file is empty" do
      before { uploader.retrieve_from_cache!(path) }

      it { is_expected.to eq('application/octet-stream') }
    end
  end
end
