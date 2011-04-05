# encoding: utf-8

require 'spec_helper'

# Seems like ImageScience doesn't work on 1.9
if RUBY_VERSION =~ /^1\.9/
  puts "ImageScience doesn't work on Ruby 1.9, skipping"
else
  describe CarrierWave::ImageScience do

    before do
      @klass = Class.new do
        include CarrierWave::ImageScience
      end
      @instance = @klass.new
      FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
      @instance.stub(:current_path).and_return(file_path('landscape_copy.jpg'))
      @instance.stub(:cached?).and_return true
    end

    after do
      FileUtils.rm(file_path('landscape_copy.jpg'))
    end

    describe '#resize_to_fill' do
      it "should resize the image to exactly the given dimensions" do
        @instance.resize_to_fill(200, 200)
        @instance.should have_dimensions(200, 200)
      end

      it "should scale up the image if it smaller than the given dimensions" do
        @instance.resize_to_fill(1000, 1000)
        @instance.should have_dimensions(1000, 1000)
      end

      it "should resize to a aspect ratio between 4:3 to 2:1 (width:height)" do
        @instance.resize_to_fill(400, 250)
        @instance.should have_dimensions(400, 250)
      end
    end

    describe '#resize_to_fit' do
      it "should resize the image to fit within the given dimensions" do
        @instance.resize_to_fit(200, 200)
        @instance.should have_dimensions(200, 150)
      end

      it "should scale up the image if it smaller than the given dimensions" do
        @instance.resize_to_fit(1000, 1000)
        @instance.should have_dimensions(1000, 750)
      end
    end

    describe '#resize_to_limit' do
      it "should resize the image to fit within the given dimensions" do
        @instance.resize_to_limit(200, 200)
        @instance.should have_dimensions(200, 150)
      end

      it "should not scale up the image if it smaller than the given dimensions" do
        @instance.resize_to_limit(1000, 1000)
        @instance.should have_dimensions(640, 480)
      end
    end

  end
end
