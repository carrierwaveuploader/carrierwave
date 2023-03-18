require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '20071201-1234-1234-2255' }
  let(:test_file) { File.open(file_path('landscape.jpg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    subject { uploader.cache!(test_file) }

    before { allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id) }

    describe "image width range" do
      before { allow(uploader).to receive(:width_range).and_return(range) }

      context 'without a processing module' do
        let(:range) { 1..1000 }

        it "raises an error" do
          expect { subject }.to raise_error('You need to include one of CarrierWave::MiniMagick, CarrierWave::RMagick, or CarrierWave::Vips to perform image dimension validation')
        end
      end

      context 'with a processing module' do
        before { uploader_class.include(CarrierWave::MiniMagick) }

        context "when the range is not specified" do
          let(:range) { nil }

          it "doesn't raise an integrity error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when the width is equal to the minimum" do
          let(:range) { 640..1000 }

          it "doesn't raise an integrity error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when the width is below the minimum" do
          let(:range) { 641..1000 }

          it "raises an integrity error" do
            expect { subject }.to raise_error(CarrierWave::IntegrityError, 'Image width should be greater than 641px')
          end
        end

        context "when the width is below the maximum" do
          let(:range) { 1..640 }

          it "doesn't raise an integrity error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when the width is above the maximum" do
          let(:range) { 1..639 }

          it "raises an integrity error" do
            expect { subject }.to raise_error(CarrierWave::IntegrityError, 'Image width should be less than 639px')
          end
        end

        if RUBY_VERSION.to_f >= 2.7
          context "when the minimum range is not specified" do
            let(:range) { nil..1000 }

            it "doesn't raise an integrity error" do
              expect { subject }.not_to raise_error
            end
          end

          context "when the maximum range is not specified" do
            let(:range) { 1..nil }

            it "doesn't raise an integrity error" do
              expect { subject }.not_to raise_error
            end
          end
        end
      end
    end

    describe "image height range" do
      before { allow(uploader).to receive(:height_range).and_return(range) }

      context 'without a processing module' do
        let(:range) { 1..1000 }

        it "raises an error" do
          expect { subject }.to raise_error('You need to include one of CarrierWave::MiniMagick, CarrierWave::RMagick, or CarrierWave::Vips to perform image dimension validation')
        end
      end

      context 'with a processing module' do
        before { uploader_class.include(CarrierWave::MiniMagick) }

        context "when the range is not specified" do
          let(:range) { nil }

          it "doesn't raise an integrity error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when the height is equal to the minimum" do
          let(:range) { 480..1000 }

          it "doesn't raise an integrity error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when the height is below the minimum" do
          let(:range) { 481..1000 }

          it "raises an integrity error" do
            expect { subject }.to raise_error(CarrierWave::IntegrityError, 'Image height should be greater than 481px')
          end
        end

        context "when the height is below the maximum" do
          let(:range) { 1..480 }

          it "doesn't raise an integrity error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when the height is above the maximum" do
          let(:range) { 1..479 }

          it "raises an integrity error" do
            expect { subject }.to raise_error(CarrierWave::IntegrityError, 'Image height should be less than 479px')
          end
        end

        if RUBY_VERSION.to_f >= 2.7
          context "when the minimum range is not specified" do
            let(:range) { nil..1000 }

            it "doesn't raise an integrity error" do
              expect { subject }.not_to raise_error
            end
          end

          context "when the maximum range is not specified" do
            let(:range) { 1..nil }

            it "doesn't raise an integrity error" do
              expect { subject }.not_to raise_error
            end
          end
        end
      end
    end
  end
end
