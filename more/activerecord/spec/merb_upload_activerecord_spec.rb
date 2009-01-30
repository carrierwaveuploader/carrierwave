require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::ActiveRecord do
  
  describe '.attach_uploader' do
    
    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }
    after { Event.delete_all }
    
    before do
      @class = Class.new(ActiveRecord::Base)
      @class.table_name = "events"
      @uploader = Class.new(Merb::Upload::AttachableUploader)
      @class.attach_uploader(@uploader)
      @event = @class.new
    end
    
    describe '#file' do
      
      it "should return nil when nothing has been assigned" do
        @event.file.should be_nil
      end
      
      it "should cache a file" do
        @event.file = stub_file('test.jpeg')
      end
      
    end
    
  end
  
end