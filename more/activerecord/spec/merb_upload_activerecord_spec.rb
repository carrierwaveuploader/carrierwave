require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::ActiveRecord do
  
  describe '.mount_uploader' do
    
    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }
    after { Event.delete_all }
    
    before do
      @class = Class.new(ActiveRecord::Base)
      @class.table_name = "events"
      @uploader = Class.new(Merb::Upload::AttachableUploader)
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
    end
    
    describe '#image' do
      
      it "should return nil when nothing has been assigned" do
        @event.image.should be_nil
      end
    
    end
    
    describe '#image=' do
      
      it "should cache a file" do
        @event.image = stub_file('test.jpeg')
        @event.image.should be_an_instance_of(@uploader)
      end
      
      it "should copy a file into into the cache directory" do
        @event.image = stub_file('test.jpeg')
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
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
      
      it "should do nothing when a validation fails" do
        @class.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('test.jpeg')
        @event.save.should be_false
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
    end
    
  end
  
end