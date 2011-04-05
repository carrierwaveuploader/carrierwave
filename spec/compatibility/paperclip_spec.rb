# encoding: utf-8

require 'spec_helper'

require 'carrierwave/orm/activerecord'

module Rails; end unless defined?(Rails)

describe CarrierWave::Compatibility::Paperclip do

  before do
    Rails.stub(:root).and_return('/rails/root')
    Rails.stub(:env).and_return('test')
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
      @uploader.store_path("monkey.png").should == "/rails/root/public/system/monkeys/23/original/monkey.png"
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

    it "should interpolate the id partition" do
      @uploader.stub!(:paperclip_path).and_return("/foo/:id_partition/bar")
      @uploader.store_path("monkey.png").should == "/foo/000/000/023/bar"
    end
  end

end
