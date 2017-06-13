require 'spec_helper'

describe CarrierWave::RMagick, :rmagick => true do

  let(:klass) { Class.new(CarrierWave::Uploader::Base) { include CarrierWave::RMagick } }
  let(:instance) { klass.new }
  let(:landscape_file_path) { file_path('landscape.jpg') }
  let(:landscape_file_copy_path) { file_path('landscape_copy.jpg') }

  before do
    FileUtils.cp(landscape_file_path, landscape_file_copy_path)
    allow(instance).to receive(:cached?).and_return true
    allow(instance).to receive(:file).and_return(CarrierWave::SanitizedFile.new(landscape_file_copy_path))
  end

  after do
    FileUtils.rm(landscape_file_copy_path) if File.exist?(file_path('landscape_copy.jpg'))
    FileUtils.rm(landscape_file_copy_path) if File.exist?(file_path('landscape_copy.jpg'))
  end

  describe '#convert' do
    it "converts the image to the given format" do
      instance.convert(:png)
      expect(instance.file.extension).to eq('png')
      expect(instance).to be_format('png')
    end
  end

  describe '#resize_to_fill' do
    it "resizes the image to exactly the given dimensions and maintain file type" do
      instance.resize_to_fill(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('JPEG')
    end

    it "resizes the image to exactly the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_fill(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('PNG')
      expect(instance.file.extension).to eq('png')
    end

    it "scales up the image if it smaller than the given dimensions" do
      instance.resize_to_fill(1000, 1000)
      expect(instance).to have_dimensions(1000, 1000)
    end
  end

  describe '#resize_and_pad' do
    it "resizes the image to exactly the given dimensions and maintain file type" do
      instance.resize_and_pad(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('JPEG')
    end

    it "resize the image to exactly the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_and_pad(200, 200)

      expect(instance).to have_dimensions(200, 200)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('PNG')
      expect(instance.file.extension).to eq('png')
    end

    it "pads with white" do
      instance.resize_and_pad(200, 200)

      color = color_of_pixel(instance.current_path, 0, 0)
      expect(color).to include('#FFFFFF')
      expect(color).not_to include('#FFFFFF00')
    end

    it "pads with transparent" do
      instance.convert('png')
      instance.resize_and_pad(200, 200, :transparent)

      color = color_of_pixel(instance.current_path, 0, 0)
      expect(color).to include('#FFFFFF00')
    end

    it "doesn't pad with transparent" do
      instance.resize_and_pad(200, 200, :transparent)
      instance.convert('png')

      color = color_of_pixel(instance.current_path, 0, 0)
      expect(color).to include('#FFFFFF')
      expect(color).not_to include('#FFFFFF00')
    end

    it "pads with given color" do
      instance.resize_and_pad(200, 200, '#888')
      color = color_of_pixel(instance.current_path, 0, 0)

      expect(color).to include('#888888')
    end

    it "scales up the image if it smaller than the given dimensions" do
      instance.resize_and_pad(1000, 1000)

      expect(instance).to have_dimensions(1000, 1000)
    end
  end

  describe '#resize_to_fit' do
    it "resizes the image to fit within the given dimensions and maintain file type" do
      instance.resize_to_fit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('JPEG')
    end

    it "resize the image to fit within the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_fit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('PNG')
    end

    it "scales up the image if it smaller than the given dimensions" do
      instance.resize_to_fit(1000, 1000)

      expect(instance).to have_dimensions(1000, 750)
    end
  end

  describe '#resize_to_limit' do
    it "resizes the image to fit within the given dimensions and maintain file type" do
      instance.resize_to_limit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('JPEG')
    end

    it "resizes the image to fit within the given dimensions and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_limit(200, 200)

      expect(instance).to have_dimensions(200, 150)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('PNG')
      expect(instance.file.extension).to eq('png')
    end

    it "doesn't scale up the image if it smaller than the given dimensions" do
      instance.resize_to_limit(1000, 1000)
      expect(instance).to have_dimensions(640, 480)
    end
  end

  describe '#resize_to_geometry_string' do
    it "resizes the image to comply with `200x200^` Geometry String spec and maintain file type" do
      instance.resize_to_geometry_string('200x200^')

      expect(instance).to have_dimensions(267, 200)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('JPEG')
    end

    it "resizes the image to comply with `200x200^` Geometry String spec and maintain updated file type" do
      instance.convert('png')
      instance.resize_to_geometry_string('200x200^')

      expect(instance).to have_dimensions(267, 200)
      expect(::Magick::Image.read(instance.current_path).first.format).to eq('PNG')
      expect(instance.file.extension).to eq('png')
    end

    it "resizes the image to have 125% larger dimensions" do
      instance.resize_to_geometry_string('125%')
      expect(instance).to have_dimensions(800, 600)
    end

    it "resizes the image to have a given height" do
      instance.resize_to_geometry_string('x256')
      expect(instance).to have_height(256)
    end

    it "resizes the image to have a given width" do
      instance.resize_to_geometry_string('256x')
      expect(instance).to have_width(256)
    end
  end

  describe "#manipulate!" do
    let(:image) { ::Magick::Image.read(landscape_file_path) }

    it 'supports passing write options to RMagick' do
      allow(::Magick::Image).to receive_messages(:read => image)
      expect_any_instance_of(::Magick::Image::Info).to receive(:quality=).with(50)
      expect_any_instance_of(::Magick::Image::Info).to receive(:depth=).with(8)

      instance.manipulate! do |image, index, options|
        options[:write] = {
          :quality => 50,
          :depth => 8
        }
        image
      end
    end

    it 'supports passing read options to RMagick' do
      expect_any_instance_of(::Magick::Image::Info).to receive(:density=).with(10)
      expect_any_instance_of(::Magick::Image::Info).to receive(:size=).with("200x200")

      instance.manipulate! :read => {
          :density => 10,
          :size => %{"200x200"}
        }
    end
  end

  describe "#width and #height" do
    it "returns the width and height of the image" do
      instance.resize_to_fill(200, 300)
      expect(instance.width).to eq(200)
      expect(instance.height).to eq(300)
    end
  end

  describe '#dimension_from' do
    it 'evaluates procs' do
      instance.resize_to_fill(Proc.new { 200 }, Proc.new { 200 })

      expect(instance).to have_dimensions(200, 200)
    end

    it 'evaluates procs with uploader instance' do
      width_argument = nil
      width = Proc.new do |uploader|
        width_argument = uploader
        200
      end
      height_argument = nil
      height = Proc.new do |uploader|
        height_argument = uploader
        200
      end
      instance.resize_to_fill(width, height)

      expect(instance).to have_dimensions(200, 200)
      expect(instance).to eq(width_argument)
      expect(instance).to eq(height_argument)
    end
  end

  describe "test errors" do
    context "invalid image file" do
      before do
        File.open(instance.current_path, 'w') { |f| f.puts "bogus" }
      end

      it "fails to process a non image file" do
        expect {instance.resize_to_limit(200, 200)}.to raise_exception(CarrierWave::ProcessingError, /^Failed to manipulate with rmagick, maybe it is not an image\?/)
      end

      it "uses I18n" do
        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :rmagick_processing_error => "Kon bestand niet met rmagick bewerken, misschien is het geen beeld bestand?"
          }
        }) do
          expect {instance.resize_to_limit(200, 200)}.to raise_exception(CarrierWave::ProcessingError, /^Kon bestand niet met rmagick bewerken, misschien is het geen beeld bestand\?/)
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
