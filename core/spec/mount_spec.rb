require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::Mount do
  
  include SanitizedFileSpecHelper
  
  describe '.mount_uploader' do
    
    before do
      @class = Class.new
      @class.send(:extend, Merb::Upload::Mount)
      
      @uploader = Class.new(Merb::Upload::Uploader)

      @class.mount_uploader(:image, @uploader)
      @instance = @class.new
    end
    
    describe '#image' do
      
      it "should return nil when nothing has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return(nil)
        @instance.image.should be_nil
      end
      
      it "should return nil when an empty string has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return('')
        @instance.image.should be_nil
      end
      
      it "should retrieve a file from the storage if a value is stored in the database" do
        @instance.should_receive(:read_uploader).with(:image).and_return('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
      end
      
      it "should set the path to the store dir" do
        @instance.should_receive(:read_uploader).with(:image).and_return('test.jpg')
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    
    end
    
    describe '#image=' do
      
      it "should cache a file" do
        @instance.should_receive(:write_uploader).with(:image, 'test.jpg')
        @instance.image = stub_file('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
      end
      
      it "should copy a file into into the cache directory" do
        @instance.should_receive(:write_uploader).with(:image, 'test.jpg')
        @instance.image = stub_file('test.jpg')
        @instance.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should do nothing when nil is assigned" do
        @instance.should_not_receive(:write_uploader)
        @instance.image = nil
      end
      
      it "should do nothing when an empty string is assigned" do
        @instance.should_not_receive(:write_uploader)
        @instance.image = ''
      end
      
    end
    
  end
  
end