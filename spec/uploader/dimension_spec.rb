require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '20071201-1234-1234-2255' }
  let(:test_file) { File.open(file_path('landscape.jpg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    subject { lambda { uploader.cache!(test_file) } }

    before { allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id) }

    describe "image width range and height range" do
      before { allow(uploader).to receive(:dimension_ranges).and_return(ranges) }

      context 'when no processing module' do
        let(:ranges) { [1..1000, 1..1000] }

        it "raises an integrity error" do
          is_expected.to raise_error(CarrierWave::IntegrityError, 'You need to include one of CarrierWave::MiniMagick, CarrierWave::RMagick, or CarrierWave::Vips')
        end
      end

      context 'when use MiniMagick' do
        before { uploader_class.include(CarrierWave::MiniMagick) }

        context "when not specified" do
          let(:ranges) { nil }

          it "doesn't raise an integrity error" do
            is_expected.not_to raise_error
          end
        end

        context "when below the width minimum" do
          let(:ranges) { [641..1000, 1..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when below the width minimum (endless) " do
          let(:ranges) { [641.., 1..] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when above the width maximum" do
          let(:ranges) { [1..639, 1..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        context "when above the width maximum (beginless)" do
          let(:ranges) { [..639, ..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        context "when below the height minimum" do
          let(:ranges) { [1..1000, 481..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when below the height minimum (endless) " do
          let(:ranges) { [1.., 481..] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when above the height maximum" do
          let(:ranges) { [1..1000, 1..479] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        context "when above the height maximum (beginless)" do
          let(:ranges) { [..1000, ..479] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        context "when inside the range" do
          let(:ranges) { [1..1000, 1..1000] }

          it "doesn't raise an integrity error" do
            is_expected.not_to raise_error
          end
        end
      end

      context 'when use RMagick' do
        before { uploader_class.include(CarrierWave::RMagick) }

        context "when not specified" do
          let(:ranges) { nil }

          it "doesn't raise an integrity error" do
            is_expected.not_to raise_error
          end
        end

        context "when below the width minimum" do
          let(:ranges) { [641..1000, 1..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when below the width minimum (endless) " do
          let(:ranges) { [641.., 1..] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when above the width maximum" do
          let(:ranges) { [1..639, 1..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        context "when above the width maximum (beginless)" do
          let(:ranges) { [..639, ..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        context "when below the height minimum" do
          let(:ranges) { [1..1000, 481..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when below the height minimum (endless) " do
          let(:ranges) { [1.., 481..] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when above the height maximum" do
          let(:ranges) { [1..1000, 1..479] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        context "when above the height maximum (beginless)" do
          let(:ranges) { [..1000, ..479] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        context "when inside the range" do
          let(:ranges) { [1..1000, 1..1000] }

          it "doesn't raise an integrity error" do
            is_expected.not_to raise_error
          end
        end
      end

      context 'when use Vips' do
        before { uploader_class.include(CarrierWave::Vips) }

        context "when not specified" do
          let(:ranges) { nil }

          it "doesn't raise an integrity error" do
            is_expected.not_to raise_error
          end
        end

        context "when below the width minimum" do
          let(:ranges) { [641..1000, 1..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when below the width minimum (endless) " do
          let(:ranges) { [641.., 1..] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when above the width maximum" do
          let(:ranges) { [1..639, 1..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        context "when above the width maximum (beginless)" do
          let(:ranges) { [..639, ..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        context "when below the height minimum" do
          let(:ranges) { [1..1000, 481..1000] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when below the height minimum (endless) " do
          let(:ranges) { [1.., 481..] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when above the height maximum" do
          let(:ranges) { [1..1000, 1..479] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        context "when above the height maximum (beginless)" do
          let(:ranges) { [..1000, ..479] }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        context "when inside the range" do
          let(:ranges) { [1..1000, 1..1000] }

          it "doesn't raise an integrity error" do
            is_expected.not_to raise_error
          end
        end
      end
    end
  end
end
