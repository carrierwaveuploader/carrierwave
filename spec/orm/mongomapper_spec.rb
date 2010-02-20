# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

require 'carrierwave/orm/mongomapper'

MongoMapper.database = "carrierwave_test"

describe CarrierWave::MongoMapper do
  
  before do
    uploader = Class.new(CarrierWave::Uploader::Base)
    
    @class = Class.new
    @class.class_eval do
      include MongoMapper::Document
      mount_uploader :image, uploader
    end
    
    @uploader = uploader
  end
  
  describe '#image' do
    
    context "when nothing is assigned" do
      
      before do
        @document = @class.new
      end
      
      it "returns a blank uploader" do
        @document.image.should be_blank
      end
      
    end
    
    context "when an empty string is assigned" do
      
      before do
        @document = @class.new(:image_filename => "")
        @document.save
      end
      
      it "returns a blank uploader" do
        @saved_doc = @class.first
        @saved_doc.image.should be_blank
      end
      
    end
    
    context "when a filename is saved in the database" do
      
      before do
        @document = @class.new(:image_filename => "test.jpg")
        @document.save
        @doc = @class.first
      end
      
      it "returns an uploader" do
        @doc.image.should be_an_instance_of(@uploader)
      end
      
      it "sets the path to the store directory" do
        @doc.image.current_path.should == public_path('uploads/test.jpg')
      end
      
    end
    
  end
  
  describe '#image=' do
    
    before do
      @doc = @class.new
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
        @doc.image.should be_an_instance_of(@uploader)
      end

      it "should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes" do
        @doc[:image_filename].should be_nil
      end

      it "should copy a file into into the cache directory" do
        @doc.image = stub_file('test.jpeg')
        @doc.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
    end
    
  end
  
  describe "#save" do
    
    before do
      @doc = @class.new
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
        @doc.image.should be_an_instance_of(@uploader)
        @doc.image.current_path.should == public_path('uploads/test.jpg')
      end
      
      it "saves the filename in the database" do
        @doc.image = stub_file('test.jpg')
        @doc.save
        @doc[:image_filename].should == 'test.jpg'
      end
      
      context "when remove_image? is true" do
        
        it "removes the image" do
          @doc.image = stub_file('test.jpeg')
          @doc.save
          @doc.remove_image = true
          @doc.save
          @doc.image.should be_blank
          @doc[:image_filename].should == ''
        end
        
      end
      
    end
    
  end
  
  describe '#destroy' do
    
    before do
      @doc = @class.new
    end
    
    describe "when file assigned" do
    
      it "removes the file from the filesystem" do
        @doc.image = stub_file('test.jpeg')
        @doc.save.should be_true
        File.exist?(public_path('uploads/test.jpeg')).should be_true
        @doc.image.should be_an_instance_of(@uploader)
        @doc.image.current_path.should == public_path('uploads/test.jpeg')
        @doc.destroy
        File.exist?(public_path('uploads/test.jpeg')).should be_false
      end  
      
    end
    
    describe "when file is not assigned" do
      
      it "deletes the instance of @class after save" do
        @doc.save
        @class.count.should eql(1)
        @doc.destroy
      end
      
      it "deletes the instance of @class after save and then re-looking up the instance" do
        # this fails with TypeError in 'CarrierWave::MongoMapper#destroy when file is not assigned deletes the instance of @class' can't modify frozen object
        @doc.save
        @class.count.should eql(1)
        @doc = @class.first
        @doc.destroy
      end
      
    end
    
  end
  
  
end
