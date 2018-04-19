require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '20071201-1234-1234-2255' }
  let(:test_file) { File.open(file_path('test.jpg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    subject { lambda { uploader.cache!(test_file) } }

    before { allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id) }

    describe "file size range" do
      before { allow(uploader).to receive(:size_range).and_return(range) }

      context "when not specified" do
        let(:range) { nil }

        it "doesn't raise an integrity error" do
          is_expected.not_to raise_error
        end
      end

      context "when below the minimum" do
        let(:range) { 2097152..4194304 }

        it "raises an integrity error" do
          is_expected.to raise_error(CarrierWave::IntegrityError, 'File size should be greater than 2 MB')
        end
      end

      context "when above the maximum" do
        let(:range) { 0..10 }

        it "raises an integrity error" do
          is_expected.to raise_error(CarrierWave::IntegrityError, 'File size should be less than 10 Bytes')
        end
      end

      context "when inside the range" do
        let(:range) { 0..100 }

        it "doesn't raise an integrity error" do
          is_expected.not_to raise_error
        end
      end
    end
  end
end
