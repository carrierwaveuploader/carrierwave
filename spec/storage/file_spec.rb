# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Storage::File do
  
  let(:klass) { Class.new(CarrierWave::Uploader::Base) }
  subject { klass.new }
  
  after do
    FileUtils.rm_rf(public_path)
  end

  context "when configuration is left at default" do
    
    it "should generate a correct url" do
      subject.store! File.open(file_path("test.jpg"))
      subject.current_path.should == "#{klass.root}#{subject.url}"
    end
    
  end
  
  context "when config.file_directory has been set" do
    
    before { klass.file_directory = "system" }
    
    it "should store the file in ./public/system" do
      subject.store! File.open(file_path("test.jpg"))
      subject.current_path.should =~ /\/public\/system\/uploads\/test.jpg$/
    end
    
    it "should generate a correct url" do
      subject.store! File.open(file_path("test.jpg"))
      subject.url.should == "/system/uploads/test.jpg"
    end
    
  end
  

end