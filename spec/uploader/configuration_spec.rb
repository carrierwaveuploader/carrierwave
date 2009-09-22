# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'


describe CarrierWave do
  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
  end

  describe '.configure' do
    it "should proxy to Uploader configuration" do
      CarrierWave::Uploader::Base.add_config :test_config
      CarrierWave.configure do |config|
        config.test_config = "foo"
      end
      CarrierWave::Uploader::Base.test_config.should == 'foo'
    end
  end
end

describe CarrierWave::Uploader::Base do
  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
  end

  describe '.configure' do
    it "should set a configuration parameter" do
      @uploader_class.add_config :foo_bar
      @uploader_class.configure do |config|
        config.foo_bar = "monkey"
      end
      @uploader_class.foo_bar.should == 'monkey'
    end
  end
  
  describe '.add_config' do
    it "should add a class level accessor" do
      @uploader_class.add_config :foo_bar
      @uploader_class.foo_bar = 'foo'
      @uploader_class.foo_bar.should == 'foo'
    end
    
    it "should be inheritable" do
      @child_class = Class.new(@uploader_class)
      @uploader_class.add_config :foo_bar

      @uploader_class.foo_bar = 'foo'
      @uploader_class.foo_bar.should == 'foo'

      #@child_class.foo_bar.should == 'foo'

      @child_class.foo_bar = 'bar'
      @child_class.foo_bar.should == 'bar'

      @uploader_class.foo_bar.should == 'foo'
    end
    
    it "should add an instance level accessor" do
      @uploader_class.add_config :foo_bar
      @uploader_class.foo_bar = 'foo'
      @uploader_class.new.foo_bar.should == 'foo'
    end
    
    it "should add a convenient in-class setter" do
      @uploader_class.add_config :foo_bar
      @uploader_class.foo_bar "monkey"
      @uploader_class.foo_bar.should == "monkey"
    end
  end
end