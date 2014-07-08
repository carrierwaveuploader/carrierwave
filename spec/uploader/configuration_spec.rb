# encoding: utf-8

require 'spec_helper'


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

  describe ".storage" do
    it "should set the storage if an argument is given" do
      storage = double('some kind of storage')
      @uploader_class.storage storage
      @uploader_class.storage.should == storage
    end

    it "should default to file" do
      @uploader_class.storage.should == CarrierWave::Storage::File
    end

    it "should set the storage from the configured shortcuts if a symbol is given" do
      @uploader_class.storage :file
      @uploader_class.storage.should == CarrierWave::Storage::File
    end

    it "should remember the storage when inherited" do
      @uploader_class.storage :fog
      subclass = Class.new(@uploader_class)
      subclass.storage.should == CarrierWave::Storage::Fog
    end

    it "should be changeable when inherited" do
      @uploader_class.storage :fog
      subclass = Class.new(@uploader_class)
      subclass.storage.should == CarrierWave::Storage::Fog
      subclass.storage :file
      subclass.storage.should == CarrierWave::Storage::File
    end
  end


  describe '.add_config' do
    it "should add a class level accessor" do
      @uploader_class.add_config :foo_bar
      @uploader_class.foo_bar = 'foo'
      @uploader_class.foo_bar.should == 'foo'
    end

    ['foo', :foo, 45, ['foo', :bar]].each do |val|
      it "should be inheritable for a #{val.class}" do
        @uploader_class.add_config :foo_bar
        @child_class = Class.new(@uploader_class)

        @uploader_class.foo_bar = val
        @uploader_class.foo_bar.should == val
        @child_class.foo_bar.should == val

        @child_class.foo_bar = "bar"
        @child_class.foo_bar.should == "bar"

        @uploader_class.foo_bar.should == val
      end
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

    describe "assigning a proc to a config attribute" do
      before(:each) do
        @uploader_class.add_config :hoobatz
        @uploader_class.hoobatz = this_proc
      end

      context "when the proc accepts no arguments" do
        let(:this_proc) { proc { "a return value" } }

        it "calls the proc without arguments" do
          @uploader_class.new.hoobatz.should == "a return value"
        end
      end

      context "when the proc accepts one argument" do
        let(:this_proc) { proc { |arg1| arg1.should be_an_instance_of(@uploader_class) } }

        it "calls the proc with an instance of the uploader" do
          @uploader_class.new.hoobatz
        end
      end
    end
  end
end
