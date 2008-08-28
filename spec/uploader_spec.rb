require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::Uploader do
  
  before do
    @uploader = Merb::Upload::Uploader.new('something')
  end

  describe '#identifier' do
    it "should be remembered" do
      @uploader.identifier.should == 'something'
    end
    
    it "should be changeable" do
      @uploader.identifier = 'anotherthing'
      @uploader.identifier.should == 'anotherthing'
    end
  end
  
  describe '#store_dir' do
    it "should default to the config option" do
      @uploader.store_dir.should == Merb.root / 'public' / 'uploads'
    end
  end
  
  describe '#tmp_dir' do
    it "should default to the config option" do
      @uploader.tmp_dir.should == Merb.root / 'public' / 'uploads' / 'tmp'
    end
  end
  
  describe '#filename' do
    it "should default to the identifier" do
      @uploader.filename.should == 'something'
    end
  end
  
end