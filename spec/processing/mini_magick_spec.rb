require 'spec_helper'

describe CarrierWave::MiniMagick do
  let(:klass) { Class.new(CarrierWave::Uploader::Base) { include CarrierWave::MiniMagick } }

  let(:instance) { klass.new }
  let(:landscape_file_path) { file_path('landscape.jpg') }
  let(:landscape_copy_file_path) { file_path('landscape_copy.jpg') }

  before do
    FileUtils.cp(landscape_file_path, landscape_copy_file_path)
    allow(instance).to receive(:cached?).and_return true
    allow(instance).to receive(:url).and_return nil
    allow(instance).to receive(:file).and_return(CarrierWave::SanitizedFile.new(landscape_copy_file_path))
  end

  after { FileUtils.rm(landscape_copy_file_path) if File.exist?(landscape_copy_file_path) }

  describe "#convert" do
    it "converts from one format to another" do
      instance.convert('png')
      expect(instance.file.extension).to eq('png')
      expect(instance).to be_format('png')
    end

    it "converts all pages when no page number is specified" do
      expect_any_instance_of(::MiniMagick::Image).to receive(:format).with('png', nil).once
      instance.convert('png')
    end

    it "converts specific page" do
      expect_any_instance_of(::MiniMagick::Image).to receive(:format).with('png', 1).once
      instance.convert('png', 1)
    end
  end

  describe '#resize_to_fill' do
    it "resizes the image to exactly the given dimensions and maintain file type" do
      instance.resize_to_fill(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/JPEG/)
    end

    it "resizes the image to exactly the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_fill(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/PNG/)
      expect(instance.file.extension).to eq('png')
    end

    it "scales up the image if it smaller than the given dimensions" do
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to_not include('Quality: 70')

      instance.resize_to_fill(1000, 1000, combine_options: { quality: 70 })

      expect(instance).to have_dimensions(1000, 1000)
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to include('Quality: 70')
    end
  end

  describe '#resize_and_pad' do
    it "resizes the image to exactly the given dimensions and maintain file type" do
      instance.resize_and_pad(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/JPEG/)
    end

    it "resizes the image to exactly the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_and_pad(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/PNG/)
    end

    it "scales up the image if it smaller than the given dimensions" do
      instance.resize_and_pad(1000, 1000)

      expect(instance).to have_dimensions(1000, 1000)
    end

    it "pads with white" do
      instance.resize_and_pad(200, 200)

      color_of_pixel(instance.current_path, 0, 0).tap do |color|
        expect(color).to include('#FFFFFF')
        expect(color).not_to include('#FFFFFF00')
      end
    end

    it "pads with transparent" do
      instance.convert('png')
      instance.resize_and_pad(200, 200, :transparent)

      expect(color_of_pixel(instance.current_path, 0, 0)).to include('#FFFFFF00')
    end

    it "doesn't pad with transparent" do
      instance.resize_and_pad(200, 200, :transparent)
      instance.convert('png')

      color_of_pixel(instance.current_path, 0, 0).tap do |color|
        expect(color).to include('#FFFFFF')
        expect(color).not_to include('#FFFFFF00')
      end
    end

    it 'accepts combine_options and set quality' do
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to_not include('Quality: 70')

      instance.resize_and_pad(1000, 1000, combine_options: {quality: 70})

      expect(instance).to have_dimensions(1000, 1000)
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to include('Quality: 70')
    end
  end

  describe '#resize_to_fit' do
    it "resizes the image to fit within the given dimensions and maintain file type" do
      instance.resize_to_fit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/JPEG/)
    end

    it "resizes the image to fit within the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_fit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/PNG/)
      expect(instance.file.extension).to eq('png')
    end

    it 'scales up the image if it smaller than the given dimensions and set quality' do
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to_not include('Quality: 70')

      instance.resize_to_fit(1000, 1000, combine_options: {quality: 70})

      expect(instance).to have_dimensions(1000, 750)
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to include('Quality: 70')
    end
  end

  describe '#resize_to_limit' do
    it 'resizes the image to fit within the given dimensions, maintain file type and set quality' do
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to_not include('Quality: 70')

      instance.resize_to_limit(200, 200, combine_options: {quality: 70})

      expect(instance).to have_dimensions(200, 150)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/JPEG/)
      expect(::MiniMagick::Tool::Identify.new.verbose(instance.current_path).call).to include('Quality: 70')
    end

    it "resizes the image to fit within the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_limit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::MiniMagick::Image.open(instance.current_path)['format']).to match(/PNG/)
      expect(instance.file.extension).to eq('png')
    end

    it "doesn't scale up the image if it smaller than the given dimensions" do
      instance.resize_to_limit(1000, 1000)

      expect(instance).to have_dimensions(640, 480)
    end
  end

  describe "#width and #height" do
    it "returns the width and height of the image" do
      instance.resize_to_fill(200, 300)

      expect(instance.width).to eq(200)
      expect(instance.height).to eq(300)
    end
  end

  describe "test errors" do
    context "invalid image file" do
      before { File.open(instance.current_path, 'w') { |f| f.puts "bogus" } }

      it "fails to process a non image file" do
        expect { instance.resize_to_limit(200, 200) }.to raise_exception(CarrierWave::ProcessingError, /^Failed to manipulate with MiniMagick, maybe it is not an image\?/)
      end

      it "uses I18n" do
        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :mini_magick_processing_error => "Kon bestand niet met MiniMagick bewerken, misschien is het geen beeld bestand?"
          }
        }) do
          expect {instance.resize_to_limit(200, 200)}.to raise_exception(CarrierWave::ProcessingError, /^Kon bestand niet met MiniMagick bewerken, misschien is het geen beeld bestand\?/)
        end
      end

      it "doesn't suppress errors when translation is unavailable" do
        change_locale_and_store_translations(:foo, {}) do
          expect { instance.resize_to_limit(200, 200) }.to raise_exception( CarrierWave::ProcessingError )
        end
      end

      context ":en locale is not available and enforce_available_locales is true" do
        it "doesn't suppress errors" do
          change_and_enforece_available_locales(:nl, [:nl, :foo]) do
            expect { instance.resize_to_limit(200, 200) }.to raise_exception(CarrierWave::ProcessingError)
          end
        end
      end
    end
  end
end
