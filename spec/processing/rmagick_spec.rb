# encoding: utf-8

require 'spec_helper'

describe CarrierWave::RMagick do

  before do
    @klass = Class.new do
      include CarrierWave::RMagick
    end
    @instance = @klass.new
    FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
    @instance.stub(:current_path).and_return(file_path('landscape_copy.jpg'))
    @instance.stub(:cached?).and_return true
  end

  after do
    FileUtils.rm(file_path('landscape_copy.jpg'))
  end

  describe '#convert' do
    it "should convert the image to the given format" do
      @instance.convert(:png)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'PNG'
    end
  end

  describe '#resize_to_fill' do
    it "should resize the image to exactly the given dimensions and maintain file type" do
      @instance.resize_to_fill(200, 200)
      @instance.should have_dimensions(200, 200)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'JPEG'
    end

    it "should resize the image to exactly the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_fill(200, 200)
      @instance.should have_dimensions(200, 200)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'PNG'
    end

    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_to_fill(1000, 1000)
      @instance.should have_dimensions(1000, 1000)
    end
  end

  describe '#resize_and_pad' do
    it "should resize the image to exactly the given dimensions and maintain file type" do
      @instance.resize_and_pad(200, 200)
      @instance.should have_dimensions(200, 200)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'JPEG'
    end

    it "should resize the image to exactly the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_and_pad(200, 200)
      @instance.should have_dimensions(200, 200)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'PNG'
    end

    it "should pad with white" do
      @instance.resize_and_pad(200, 200)
      color = color_of_pixel(@instance.current_path, 0, 0)
      color.should include('#FFFFFF')
      color.should_not include('#FFFFFF00')
    end

    it "should pad with transparent" do
      @instance.convert('png')
      @instance.resize_and_pad(200, 200, :transparent)
      color = color_of_pixel(@instance.current_path, 0, 0)
      color.should include('#FFFFFF00')
    end

    it "should not pad with transparent" do
      @instance.resize_and_pad(200, 200, :transparent)
      @instance.convert('png')
      color = color_of_pixel(@instance.current_path, 0, 0)
      color.should include('#FFFFFF')
      color.should_not include('#FFFFFF00')
    end

    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_and_pad(1000, 1000)
      @instance.should have_dimensions(1000, 1000)
    end
  end

  describe '#resize_to_fit' do
    it "should resize the image to fit within the given dimensions and maintain file type" do
      @instance.resize_to_fit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'JPEG'
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_fit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'PNG'
    end

    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_to_fit(1000, 1000)
      @instance.should have_dimensions(1000, 750)
    end
  end

  describe '#resize_to_limit' do
    it "should resize the image to fit within the given dimensions and maintain file type" do
      @instance.resize_to_limit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'JPEG'
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_limit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'PNG'
    end

    it "should not scale up the image if it smaller than the given dimensions" do
      @instance.resize_to_limit(1000, 1000)
      @instance.should have_dimensions(640, 480)
    end
  end

  describe '#resize_to_geometry_string' do
    it "should resize the image to comply with `200x200^` Geometry String spec and maintain file type" do
      @instance.resize_to_geometry_string('200x200^')
      @instance.should have_dimensions(267, 200)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'JPEG'
    end

    it "should resize the image to comply with `200x200^` Geometry String spec and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_geometry_string('200x200^')
      @instance.should have_dimensions(267, 200)
      ::Magick::Image.read(@instance.current_path).first.format.should == 'PNG'
    end

    it "should resize the image to have 125% larger dimensions" do
      @instance.resize_to_geometry_string('125%')
      @instance.should have_dimensions(800, 600)
    end

    it "should resize the image to have a given height" do
      @instance.resize_to_geometry_string('x256')
      @instance.should have_height(256)
    end

    it "should resize the image to have a given width" do
      @instance.resize_to_geometry_string('256x')
      @instance.should have_width(256)
    end
  end

  describe "#manipulate!" do
    it 'should support passing write options to RMagick' do
      image = ::Magick::Image.read(file_path('landscape_copy.jpg'))
      ::Magick::Image.stub(:read => image)
      ::Magick::Image::Info.any_instance.should_receive(:quality=).with(50)
      ::Magick::Image::Info.any_instance.should_receive(:depth=).with(8)
      
      @instance.manipulate! do |image, index, options| 
        options[:write] = {
          :quality => 50,
          :depth => 8
        }
        image
      end
    end

    it 'should support passing read options to RMagick' do
      ::Magick::Image::Info.any_instance.should_receive(:density=).with(10)
      ::Magick::Image::Info.any_instance.should_receive(:size=).with("200x200")
      
      @instance.manipulate! :read => {
          :density => 10,
          :size => %{"200x200"}
        }
    end
  end

  describe "test errors" do
    context "invalid image file" do
      before do
        File.open(@instance.current_path, 'w') do |f|
          f.puts "bogus"
        end
      end

      it "should fail to process a non image file" do
        lambda {@instance.resize_to_limit(200, 200)}.should raise_exception(CarrierWave::ProcessingError, /^Failed to manipulate with rmagick, maybe it is not an image\? Original Error:/)
      end

      it "should use I18n" do
        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :rmagick_processing_error => "Kon bestand niet met rmagick bewerken, misschien is het geen beeld bestand? rmagick foutmelding: %{e}"
          }
        }) do
          lambda {@instance.resize_to_limit(200, 200)}.should raise_exception(CarrierWave::ProcessingError, /^Kon bestand niet met rmagick bewerken, misschien is het geen beeld bestand\? rmagick foutmelding:/)
        end
      end

      it "should not suppress errors when translation is unavailable" do
        change_locale_and_store_translations(:foo, {}) do
          lambda do
            @instance.resize_to_limit(200, 200)
          end.should raise_exception( CarrierWave::ProcessingError, /Not a JPEG/ )
        end
      end
    end
  end
end
