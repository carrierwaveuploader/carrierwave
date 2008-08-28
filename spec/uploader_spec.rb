require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Upload::Uploader do
  
  before do
    @uploader = Merb::Upload::Uploader.new('something')
  end
  
  after do
    FileUtils.rm_rf(public_path)
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
  
  describe '#cache!' do
    it "should cache a file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should move it to the tmp dir" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.path.should == public_path('uploads/tmp/something')
      @uploader.file.exists?.should be_true
    end
  end
  
  describe '#retrieve_from_cache!' do
    it "should cache a file" do
      @uploader.retrieve_from_cache!
      @uploader.file.should be_an_instance_of(Merb::Upload::SanitizedFile)
    end
    
    it "should set the path to the tmp dir" do
      @uploader.retrieve_from_cache!
      @uploader.file.path.should == public_path('uploads/tmp/something')
    end
  end
  
end