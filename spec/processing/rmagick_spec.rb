# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe CarrierWave::RMagick do

  before do
    @klass = Class.new do
      include CarrierWave::RMagick
    end
    @instance = @klass.new
    FileUtils.cp(file_path('landscape.jpg'), file_path('landscape_copy.jpg'))
    @instance.stub(:current_path).and_return(file_path('landscape_copy.jpg'))
  end
  
  after do
    FileUtils.rm(file_path('landscape_copy.jpg'))
  end

  describe '#convert' do
    it "should convert the image to the given format" do
      # TODO: find some way to spec this
      @instance.convert(:png)
    end
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
  end
  
  describe '#resize_and_pad' do
    it "should resize the image to exactly the given dimensions" do
      @instance.resize_and_pad(200, 200)
      @instance.should have_dimensions(200, 200)
    end
    
    it "should scale up the image if it smaller than the given dimensions" do
      @instance.resize_and_pad(1000, 1000)
      @instance.should have_dimensions(1000, 1000)
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
