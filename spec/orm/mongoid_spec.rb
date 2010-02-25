# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

require 'carrierwave/orm/mongoid'

connection = Mongo::Connection.new
Mongoid.database = connection.db("carrierwave_test")
    
MongoidUploader = Class.new(CarrierWave::Uploader::Base)
MongoidUser = Class.new
MongoidUser.class_eval do
  include Mongoid::Document
  store_in :users
  mount_uploader :image, MongoidUploader
end

describe CarrierWave::Mongoid do

  after do
    MongoidUser.collection.drop
  end

  describe '#image' do

    context "when nothing is assigned" do

      before do
        @document = MongoidUser.new
      end

      it "returns a blank uploader" do
        @document.image.should be_blank
      end

    end

    context "when an empty string is assigned" do

      before do
        @document = MongoidUser.new(:image_filename => "")
        @document.save
      end

      it "returns a blank uploader" do
        @saved_doc = MongoidUser.first
        @saved_doc.image.should be_blank
      end

    end

    context "when a filename is saved in the database" do

      before do
        @document = MongoidUser.new(:image_filename => "test.jpg")
        @document.save
        @doc = MongoidUser.first
      end

      it "returns an uploader" do
        @doc.image.should be_an_instance_of(MongoidUploader)
      end

      it "sets the path to the store directory" do
        @doc.image.current_path.should == public_path('uploads/test.jpg')
      end

    end

  end

  describe '#image=' do

    before do
      @doc = MongoidUser.new
    end

    context "when nil is assigned" do

      it "does not set the value" do
        @doc.image = nil
        @doc.image.should be_blank
      end

    end

    context "when an empty string is assigned" do

      it "does not set the value" do
        @doc.image = ''
        @doc.image.should be_blank
      end

    end

    context "when a file is assigned" do

      it "should cache a file" do
        @doc.image = stub_file('test.jpeg')
        @doc.image.should be_an_instance_of(MongoidUploader)
      end

      it "should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes" do
        @doc.image_filename.should be_nil
      end

      it "should copy a file into into the cache directory" do
        @doc.image = stub_file('test.jpeg')
        @doc.image.current_path.should =~ /^#{public_path('uploads\/tmp')}/
      end

    end

  end

  describe "#save" do

    before do
      @doc = MongoidUser.new
    end

    context "when no file is assigned" do

      it "image is blank" do
        @doc.save
        @doc.image.should be_blank
      end

    end

    context "when a file is assigned" do

      it "copies the file to the upload directory" do
        @doc.image = stub_file('test.jpg')
        @doc.save
        @doc.image.should be_an_instance_of(MongoidUploader)
        @doc.image.current_path.should == public_path('uploads/test.jpg')
      end

      it "saves the filename in the database" do
        @doc.image = stub_file('test.jpg')
        @doc.save
        @doc.image_filename.should == 'test.jpg'
      end

      context "when remove_image? is true" do

        it "removes the image" do
          @doc.image = stub_file('test.jpeg')
          @doc.save
          @doc.remove_image = true
          @doc.save
          @doc.image.should be_blank
          @doc.image_filename.should == ''
        end

      end

    end

  end

  describe '#destroy' do

    before do
      @doc = MongoidUser.new
    end

    describe "when file assigned" do

      it "removes the file from the filesystem" do
        @doc.image = stub_file('test.jpeg')
        @doc.save.should be_true
        File.exist?(public_path('uploads/test.jpeg')).should be_true
        @doc.image.should be_an_instance_of(MongoidUploader)
        @doc.image.current_path.should == public_path('uploads/test.jpeg')
        @doc.destroy
        File.exist?(public_path('uploads/test.jpeg')).should be_false
      end

    end

    describe "when file is not assigned" do

      it "deletes the instance of MongoidUser after save" do
        @doc.save
        MongoidUser.count.should eql(1)
        @doc.destroy
      end

      it "deletes the instance of MongoidUser after save and then re-looking up the instance" do
        @doc.save
        MongoidUser.count.should eql(1)
        @doc = MongoidUser.first
        @doc.destroy
      end

    end

  end


end
