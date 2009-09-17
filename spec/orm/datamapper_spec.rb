# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

require 'carrierwave/orm/datamapper'

DataMapper.setup(:default, 'sqlite3::memory:')

describe CarrierWave::DataMapper do
  
  before do
    uploader = Class.new(CarrierWave::Uploader::Base)
    
    @class = Class.new
    @class.class_eval do
      include DataMapper::Resource

      storage_names[:default] = 'events'
      
      property :id, DataMapper::Types::Serial
      property :image, String
      
      mount_uploader :image, uploader
    end
    
    @class.auto_migrate!
    
    @uploader = uploader
    
    @event = @class.new
  end
  
  describe '#image' do
    
    it "should return blank uploader when nothing has been assigned" do
      @event.image.should be_blank
    end
    
    it "should return blank uploader when an empty string has been assigned" do
      repository(:default).adapter.query("INSERT INTO events (image) VALUES ('')")
      @event = @class.first
      
      @event.image.should be_blank
    end
    
    it "should retrieve a file from the storage if a value is stored in the database" do
      repository(:default).adapter.query("INSERT INTO events (image) VALUES ('test.jpg')")
      @event = @class.first

      @event.save
      @event.reload
      @event.image.should be_an_instance_of(@uploader)
    end
    
    it "should set the path to the store dir" do
      @event.attribute_set(:image, 'test.jpeg')
      @event.save
      @event.reload
      @event.image.current_path.should == public_path('uploads/test.jpeg')
    end
  
  end
  
  describe '#image=' do
    
    it "should cache a file" do
      @event.image = stub_file('test.jpeg')
      @event.image.should be_an_instance_of(@uploader)
    end
    
    it "should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes" do
      @event.attribute_get(:image).should be_nil
    end
    
    it "should copy a file into into the cache directory" do
      @event.image = stub_file('test.jpeg')
      @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
    end
    
    it "should do nothing when nil is assigned" do
      @event.image = nil
      @event.image.should be_blank
    end
    
    it "should do nothing when an empty string is assigned" do
      @event.image = ''
      @event.image.should be_blank
    end
    
  end
  
  describe '#save' do
    
    it "should do nothing when no file has been assigned" do
      @event.save
      @event.image.should be_blank
    end
    
    it "should copy the file to the upload directory when a file has been assigned" do
      @event.image = stub_file('test.jpeg')
      @event.save
      @event.image.should be_an_instance_of(@uploader)
      @event.image.current_path.should == public_path('uploads/test.jpeg')
    end
    
    # it "should do nothing when a validation fails" do
    #   pending "how do we test with and without dm-validations?"
    #   @class.validate { |r| r.errors.add :textfile, "FAIL!" }
    #   @event.image = stub_file('test.jpeg')
    #   @event.save
    #   @event.image.should be_an_instance_of(@uploader)
    #   @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
    # end
    
    it "should assign the filename to the database" do
      @event.image = stub_file('test.jpeg')
      @event.save
      @event.reload
      @event.attribute_get(:image).should == 'test.jpeg'
    end
    
    # it "should assign the filename before validation" do
    #   pending "how do we test with and without dm-validations?"
    #   @class.validate { |r| r.errors.add_to_base "FAIL!" if r[:image].nil? }
    #   @event.image = stub_file('test.jpeg')
    #   @event.save
    #   @event.reload
    #   @event.attribute_get(:image).should == 'test.jpeg'
    # end

    it "should remove the image if remove_image? returns true" do
      @event.image = stub_file('test.jpeg')
      @event.save
      @event.remove_image = true
      @event.save
      @event.reload
      @event.image.should be_blank
      @event.attribute_get(:image).should == ''
    end

  end

  describe '#destroy' do
    
    it "should do nothing when no file has been assigned" do
      @event.destroy
    end
    
    it "should remove the file from the filesystem" do
      @event.image = stub_file('test.jpeg')
      @event.save.should be_true
      File.exist?(public_path('uploads/test.jpeg')).should be_true
      @event.image.should be_an_instance_of(@uploader)
      @event.image.current_path.should == public_path('uploads/test.jpeg')
      @event.destroy
      File.exist?(public_path('uploads/test.jpeg')).should be_false
    end

  end
  
end
