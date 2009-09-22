# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

require 'carrierwave/orm/activerecord'

module Rails
  def self.root
    File.expand_path(File.join('..'), File.dirname(__FILE__))
  end
  def self.env
    "test"
  end
end unless defined?(Rails)

describe CarrierWave::Compatibility::Paperclip do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base) do
      include CarrierWave::Compatibility::Paperclip
    end
    @model = mock('a model')
    @model.stub!(:id).and_return(23)
    @uploader = @uploader_class.new(@model, :monkey)
  end
  
  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#store_path' do
    it "should mimics paperclip default" do
      @uploader.store_path("monkey.png").should == CarrierWave::Uploader::Base.root + "/system/monkeys/23/original/monkey.png"
    end

    it "should interpolate the root path" do
      @uploader.stub!(:paperclip_path).and_return(":rails_root/foo/bar")
      @uploader.store_path("monkey.png").should == Rails.root + "/foo/bar"
    end

    it "should interpolate the attachment" do
      @uploader.stub!(:paperclip_path).and_return("/foo/:attachment/bar")
      @uploader.store_path("monkey.png").should == "/foo/monkeys/bar"
    end

    it "should interpolate the id" do
      @uploader.stub!(:paperclip_path).and_return("/foo/:id/bar")
      @uploader.store_path("monkey.png").should == "/foo/23/bar"
    end
  end

end