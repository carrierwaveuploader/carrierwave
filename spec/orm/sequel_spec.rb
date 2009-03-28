require File.dirname(__FILE__) + '/../spec_helper'

require 'carrierwave/orm/sequel'

DB = Sequel.sqlite

class Event < Sequel::Model; end
class ValidatedEvent < Event
  validates_each :image do |object, attribute, value|
    object.errors[attribute] << 'FAIL!'
  end
end

describe CarrierWave::Sequel do

  include SanitizedFileSpecHelper
  
  def setup_variables_for_class(klass)
    uploader = Class.new(CarrierWave::Uploader)
    klass.mount_uploader(:image, uploader)
    model = klass.new
    [klass, uploader, model] 
  end

  describe '.mount_uploader' do
    
    before(:all) { 
      DB.create_table :events do
      primary_key :id
      column      :image,    :string
      column      :textfile, :string
      end
    }

    after(:all) { DB.drop_table :events }
    after { Event.destroy_all }
    
    before do
      @class, @uploader, @event = setup_variables_for_class(Event)
    end
    
    describe '#image' do
      
      it "should return nil when nothing has been assigned" do
        @event.image.should be_nil
      end
      
      it "should return nil when an empty string has been assigned" do
        @event[:image] = ''
        @event.save
        @event.reload
        @event.image.should be_nil
      end
      
      it "should retrieve a file from the storage if a value is stored in the database" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload
        @event.image.should be_an_instance_of(@uploader)
      end
      
      it "should set the path to the store dir" do
        @event[:image] = 'test.jpeg'
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
        @event[:image].should be_nil
      end
      
      it "should copy a file into into the cache directory" do
        @event.image = stub_file('test.jpeg')
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should do nothing when nil is assigned" do
        @event.image = nil
        @event.image.should be_nil
      end
      
      it "should do nothing when an empty string is assigned" do
        @event.image = ''
        @event.image.should be_nil
      end
      
    end
    
    describe '#save' do
      
      it "should do nothing when no file has been assigned" do
        @event.save.should be_true
        @event.image.should be_nil
      end
      
      it "should copy the file to the upload directory when a file has been assigned" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should == public_path('uploads/test.jpeg')
      end
      
      describe 'with validation' do

        before do
          @class, @uploader, @event = setup_variables_for_class(ValidatedEvent)
        end

        it "should do nothing when a validation fails" do
          @event.image = stub_file('test.jpeg')
          @event.save.should be_false
          @event.image.should be_an_instance_of(@uploader)
          @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
        end
      end 
     
      it "should assign the filename to the database" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.reload
        @event[:image].should == 'test.jpeg'
      end
      
    end
    
    describe 'with overriddent filename' do
      
      describe '#save' do

        before do
          @uploader.class_eval do
            def filename
              model.name + File.extname(super)
            end
          end
          @event.stub!(:name).and_return('jonas')
        end

        it "should copy the file to the upload directory when a file has been assigned" do
          @event.image = stub_file('test.jpeg')
          @event.save.should be_true
          @event.image.should be_an_instance_of(@uploader)
          @event.image.current_path.should == public_path('uploads/jonas.jpeg')
        end

        it "should assign an overridden filename to the database" do
          @event.image = stub_file('test.jpeg')
          @event.save.should be_true
          @event.reload
          @event[:image].should == 'jonas.jpeg'
        end

      end

    end
    
  end
end
