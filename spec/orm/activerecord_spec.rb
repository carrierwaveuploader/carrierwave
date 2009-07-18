# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

require 'carrierwave/orm/activerecord'

# change this if sqlite is unavailable
dbconfig = {
  :adapter => 'sqlite3',
  :database => ':memory:'
}

ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :events, :force => true do |t|
      t.column :image, :string
      t.column :textfile, :string
      t.column :foo, :string
    end
  end

  def self.down
    drop_table :events
  end
end

class Event < ActiveRecord::Base; end # setup a basic AR class for testing
$arclass = 0

describe CarrierWave::ActiveRecord do
  
  describe '.mount_uploader' do
    
    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }
    after { Event.delete_all }
    
    before do
      # My god, what a horrible, horrible solution, but AR validations don't work
      # unless the class has a name. This is the best I could come up with :S
      $arclass += 1
      eval <<-RUBY
        class Event#{$arclass} < Event; end
        @class = Event#{$arclass}
      RUBY
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
    end
    
    describe '#image' do
      
      it "should return blank uploader when nothing has been assigned" do
        @event.image.should be_blank
      end
      
      it "should return blank uploader when an empty string has been assigned" do
        @event[:image] = ''
        @event.save
        @event.reload
        @event.image.should be_blank
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
        @event.image.should be_blank
      end
      
      it "should do nothing when an empty string is assigned" do
        @event.image = ''
        @event.image.should be_blank
      end

      it "should make the record invalid when an integrity error occurs" do
        @uploader.class_eval do
          def extension_white_list
            %(txt)
          end
        end
        @event.image = stub_file('test.jpg')
        @event.should_not be_valid
      end
  
      it "should make the record invalid when a processing error occurs" do
        @uploader.class_eval do
          process :monkey
          def monkey
            raise CarrierWave::ProcessingError, "Ohh noez!"
          end
        end
        @event.image = stub_file('test.jpg')
        @event.should_not be_valid
      end
      
    end
    
    describe '#save' do
      
      it "should do nothing when no file has been assigned" do
        @event.save.should be_true
        @event.image.should be_blank
      end
      
      it "should copy the file to the upload directory when a file has been assigned" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should == public_path('uploads/test.jpeg')
      end
      
      it "should do nothing when a validation fails" do
        @class.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('test.jpeg')
        @event.save.should be_false
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should assign the filename to the database" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.reload
        @event[:image].should == 'test.jpeg'
      end
      
      it "should preserve the image when nothing is assigned" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event = @class.find(@event.id)
        @event.foo = "bar"
        @event.save.should be_true
        @event[:image].should == 'test.jpeg'
      end
      
      it "should remove the image if remove_image? returns true" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image = true
        @event.save!
        @event.reload
        @event.image.should be_blank
        @event[:image].should == ''
      end

    end

    describe '#destroy' do
      
      it "should do nothing when no file has been assigned" do
        @event.save.should be_true
        @event.destroy
      end
      
      it "should remove the file from the filesystem" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should == public_path('uploads/test.jpeg')
        @event.destroy
        File.exist?(public_path('uploads/test.jpeg')).should be_false
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
    
    describe 'with validates_presence_of' do

      before do
        @class.validates_presence_of :image
        @event.stub!(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached" do
        @event.image = stub_file('test.jpeg')
        @event.should be_valid
      end

      it "should not be valid if a file has not been cached" do
        @event.should_not be_valid
      end

    end

    describe 'with validates_size_of' do

      before do
        @class.validates_size_of :image, :maximum => 40
        @event.stub!(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached that matches the size criteria" do
        @event.image = stub_file('test.jpeg')
        @event.should be_valid
      end

      it "should not be valid if a file has been cached that does not match the size criteria" do
        @event.image = stub_file('bork.txt')
        @event.should_not be_valid
      end

    end
    
  end
  
end
