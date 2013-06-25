# encoding: utf-8

require 'spec_helper'

describe CarrierWave::MiniMagick do

  before do
    @klass = Class.new do
      include CarrierWave::MiniMagick
    end
    @instance = @klass.new
    FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
    @instance.stub(:current_path).and_return(file_path('landscape_copy.jpg'))
    @instance.stub(:cached?).and_return true
  end

  after do
    FileUtils.rm(file_path('landscape_copy.jpg'))
  end

  describe "#convert" do
    it "should convert from one format to another" do
      @instance.convert('png')
      img = ::MiniMagick::Image.open(@instance.current_path)
      img['format'].should =~ /PNG/
    end
  end

  describe '#resize_to_fill' do
    it "should resize the image to exactly the given dimensions and maintain file type" do
      @instance.resize_to_fill(200, 200)
      @instance.should have_dimensions(200, 200)
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /JPEG/
    end

    it "should resize the image to exactly the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_fill(200, 200)
      @instance.should have_dimensions(200, 200)
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /PNG/
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
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /JPEG/
    end

    it "should resize the image to exactly the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_and_pad(200, 200)
      @instance.should have_dimensions(200, 200)
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /PNG/
    end

    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_and_pad(1000, 1000)
      @instance.should have_dimensions(1000, 1000)
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

  end

  describe '#resize_to_fit' do
    it "should resize the image to fit within the given dimensions and maintain file type" do
      @instance.resize_to_fit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /JPEG/
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_fit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /PNG/
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
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /JPEG/
    end

    it "should resize the image to fit within the given dimensions and maintain updated file type" do
      @instance.convert('png')
      @instance.resize_to_limit(200, 200)
      @instance.should have_dimensions(200, 150)
      ::MiniMagick::Image.open(@instance.current_path)['format'].should =~ /PNG/
    end

    it "should not scale up the image if it smaller than the given dimensions" do
      @instance.resize_to_limit(1000, 1000)
      @instance.should have_dimensions(640, 480)
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
        lambda {@instance.resize_to_limit(200, 200)}.should raise_exception(CarrierWave::ProcessingError, /^Failed to manipulate with MiniMagick, maybe it is not an image\? Original Error:/)
      end

      it "should use I18n" do
        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :mini_magick_processing_error => "Kon bestand niet met MiniMagick bewerken, misschien is het geen beeld bestand? MiniMagick foutmelding: %{e}"
          }
        }) do
          lambda {@instance.resize_to_limit(200, 200)}.should raise_exception(CarrierWave::ProcessingError, /^Kon bestand niet met MiniMagick bewerken, misschien is het geen beeld bestand\? MiniMagick foutmelding:/)
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
