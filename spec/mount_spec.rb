# encoding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

describe CarrierWave::Mount do
  
  after do
    FileUtils.rm_rf(public_path)
  end

  describe '.mount_uploader' do
    
    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      
      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader)
      @instance = @class.new
    end

    it "should maintain the ability to super" do
      @class.class_eval do
        def image_uploader
          super
        end

        def image=(val)
          super
        end
      end

      @instance.image = stub_file('test.jpg')
      @instance.image.should be_an_instance_of(@uploader)
    end
    
    it "should inherit uploaders to subclasses" do
      @subclass = Class.new(@class)
      @subclass_instance = @subclass.new
      @subclass_instance.image = stub_file('test.jpg')
      @subclass_instance.image.should be_an_instance_of(@uploader)
    end
    
    describe '#image' do
      
      it "should return a blank uploader when nothing has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).twice.and_return(nil)
        @instance.image.should be_an_instance_of(@uploader)
        @instance.image.should be_blank
      end
      
      it "should return a blank uploader when an empty string has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).twice.and_return('')
        @instance.image.should be_an_instance_of(@uploader)
        @instance.image.should be_blank
      end
      
      it "should retrieve a file from the storage if a value is stored in the database" do
        @instance.should_receive(:read_uploader).with(:image).at_least(:once).and_return('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
      end
      
      it "should set the path to the store dir" do
        @instance.should_receive(:read_uploader).with(:image).at_least(:once).and_return('test.jpg')
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    
    end
    
    describe '#image=' do
      
      it "should cache a file" do
        @instance.image = stub_file('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
      end
      
      it "should copy a file into into the cache directory" do
        @instance.image = stub_file('test.jpg')
        @instance.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end
      
      it "should do nothing when nil is assigned" do
        @instance.should_not_receive(:write_uploader)
        @instance.image = nil
      end
      
      it "should do nothing when an empty string is assigned" do
        @instance.should_not_receive(:write_uploader)
        @instance.image = stub_file('test.jpg')
      end

      it "should fail silently if the image fails an integrity check" do
        @uploader.class_eval do
          def extension_white_list
            %(txt)
          end
        end
        @instance.image = stub_file('test.jpg')
        @instance.image.should be_blank
      end
      
      it "should fail silently if the image fails to be processed" do
        @uploader.class_eval do
          process :monkey
          def monkey
            raise CarrierWave::ProcessingError, "Ohh noez!"
          end
        end
        @instance.image = stub_file('test.jpg')
      end
      
    end

    describe '#image?' do
      
      it "should be false when nothing has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return(nil)
        @instance.image?.should be_false
      end
      
      it "should be false when an empty string has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return('')
        @instance.image?.should be_false
      end

      it "should be true when a file has been cached" do
        @instance.image = stub_file('test.jpg')
        @instance.image?.should be_true
      end
    
    end

    describe '#image_url' do
      
      it "should return nil when nothing has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return(nil)
        @instance.image_url.should be_nil
      end
      
      it "should return nil when an empty string has been assigned" do
        @instance.should_receive(:read_uploader).with(:image).and_return('')
        @instance.image_url.should be_nil
      end
      
      it "should get the url from a retrieved file" do
        @instance.should_receive(:read_uploader).at_least(:once).with(:image).and_return('test.jpg')
        @instance.image_url.should == '/uploads/test.jpg'
      end

      it "should get the url from a cached file" do
        @instance.image = stub_file('test.jpg')
        @instance.image_url.should =~ %r{uploads/tmp/[\d\-]+/test.jpg}
      end

      it "should get the url from a cached file's version" do
        @uploader.version(:thumb)
        @instance.image = stub_file('test.jpg')
        @instance.image_url(:thumb).should =~ %r{uploads/tmp/[\d\-]+/thumb_test.jpg}
      end

    end

    describe '#image_cache' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
      end

      it "should return nil when nothing has been assigned" do
        @instance.image_cache.should be_nil
      end

      it "should be nil when a file has been stored" do
        @instance.image = stub_file('test.jpg')
        @instance.image.store!
        @instance.image_cache.should be_nil
      end

      it "should be the cache name when a file has been cached" do
        @instance.image = stub_file('test.jpg')
        @instance.image_cache.should =~ %r(^[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}/test\.jpg$)
      end

    end
    
    describe '#image_cache=' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
        CarrierWave::SanitizedFile.new(file_path('test.jpg')).copy_to(public_path('uploads/tmp/19990512-1202-123-1234/test.jpg'))
      end

      it "should do nothing when nil is assigned" do
        @instance.image_cache = nil
        @instance.image.should be_blank
      end

      it "should do nothing when an empty string is assigned" do
        @instance.image_cache = ''
        @instance.image.should be_blank
      end

      it "retrieve from cache when a cache name is assigned" do
        @instance.image_cache = '19990512-1202-123-1234/test.jpg'
        @instance.image.current_path.should == public_path('uploads/tmp/19990512-1202-123-1234/test.jpg')
      end

      it "should not write over a previously assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.image_cache = '19990512-1202-123-1234/monkey.jpg'
        @instance.image.current_path.should =~ /test.jpg$/
      end
    end

    describe '#remote_image_url' do
      before do
        response = mock('HTTP Response')
        response.stub!(:body).and_return('Response Body')
        Net::HTTP.stub!(:get_response).and_return(response)
      end

      it "should return nil" do
        @instance.remote_image_url.should be_nil
      end

      it "should return previously cached URL" do
        @instance.remote_image_url = 'http://www.example.com/funky/monkey.png'
        @instance.remote_image_url.should == 'http://www.example.com/funky/monkey.png'
      end
    end

    describe '#remote_image_url=' do
      before do
        response = mock('HTTP Response')
        response.stub!(:body).and_return('Response Body')
        Net::HTTP.stub!(:get_response).and_return(response)
      end

      it "should do nothing when nil is assigned" do
        @instance.remote_image_url = nil
        @instance.image.should be_blank
      end

      it "should do nothing when an empty string is assigned" do
        @instance.remote_image_url = ''
        @instance.image.should be_blank
      end

      it "retrieve from cache when a cache name is assigned" do
        @instance.remote_image_url = 'http://www.example.com/funky/monkey.png'
        @instance.image.current_path.should =~ /monkey.png$/
      end

      it "should not write over a previously assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.remote_image_url = '19990512-1202-123-1234/monkey.jpg'
        @instance.image.current_path.should =~ /test.jpg$/
      end
    end

    describe '#store_image!' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.store_image!
        @instance.image.should be_blank
      end

      it "store an assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end

      it "should remove an uploaded file when remove_image? returns true" do
        @instance.image = stub_file('test.jpg')
        path = @instance.image.current_path
        @instance.remove_image = true
        @instance.store_image!
        @instance.image.should be_blank
        File.exist?(path).should be_false
      end
    end

    describe '#remove_image!' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
      end

      it "should do nothing when no file has been uploaded" do
        @instance.remove_image!
        @instance.image.should be_blank
      end

      it "should remove an uploaded file" do
        @instance.image = stub_file('test.jpg')
        path = @instance.image.current_path
        @instance.remove_image!
        @instance.image.should be_blank
        File.exist?(path).should be_false
      end
    end

    describe '#remove_image' do
      
      it "should store a value" do
        @instance.remove_image = true
        @instance.remove_image.should be_true
      end
      
    end

    describe '#remove_image?' do
      
      it "should be true when the value is truthy" do
        @instance.remove_image = true
        @instance.remove_image?.should be_true
      end
      
      it "should be false when the value is falsey" do
        @instance.remove_image = false
        @instance.remove_image?.should be_false
      end
      
      it "should be false when the value is ''" do
        @instance.remove_image = ''
        @instance.remove_image?.should be_false
      end
      
      it "should be false when the value is '0'" do
        @instance.remove_image = '0'
        @instance.remove_image?.should be_false
      end

      it "should be false when the value is 'false'" do
        @instance.remove_image = 'false'
        @instance.remove_image?.should be_false
      end
      
    end

    describe '#image_integrity_error' do

      it "should be nil by default" do
        @instance.image_integrity_error.should be_nil
      end

      it "should be nil after a file is cached" do
        @instance.image = stub_file('test.jpg')
        @instance.image_integrity_error.should be_nil
      end

      it "should be an error instance after an integrity check has failed" do
        @uploader.class_eval do
          def extension_white_list
            %(txt)
          end
        end
        @instance.image = stub_file('test.jpg')
        @instance.image_integrity_error.should be_an_instance_of(CarrierWave::IntegrityError)
      end
    end
    
    describe '#image_processing_error' do

      it "should be nil by default" do
        @instance.image_processing_error.should be_nil
      end

      it "should be nil after a file is cached" do
        @instance.image = stub_file('test.jpg')
        @instance.image_processing_error.should be_nil
      end

      it "should be an error instance after an integrity check has failed" do
        @uploader.class_eval do
          process :monkey
          def monkey
            raise CarrierWave::ProcessingError, "Ohh noez!"
          end
        end
        @instance.image = stub_file('test.jpg')
        @instance.image_processing_error.should be_an_instance_of(CarrierWave::ProcessingError)
      end
    end

    describe '#write_image_identifier' do
      it "should write to the column" do
        @instance.should_receive(:write_uploader).with(:image, "test.jpg")
        @instance.image = stub_file('test.jpg')
        @instance.write_image_identifier
      end

      it "should remove from the column when remove_image is true" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        @instance.remove_image = true
        @instance.should_receive(:write_uploader).with(:image, "")
        @instance.write_image_identifier
      end
    end

  end
  
  describe '#mount_uploader with a block' do
   
    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      @class.mount_uploader(:image) do
        def monkey
          'blah'
        end
      end
      @instance = @class.new
    end
    
    describe '#image' do
      
      before do
        @instance.stub!(:read_uploader).and_return('test.jpg')
      end
      
      it "should return an instance of a subclass of CarrierWave::Uploader::Base" do
        @instance.image.should be_a(CarrierWave::Uploader::Base)
      end
      
      it "should set the path to the store dir" do
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    
      it "should apply any custom modifications" do
        @instance.image.monkey.should == "blah"
      end
    
    end
    
  end
  
  describe '#mount_uploader with :ignore_integrity_errors => false' do
   
    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      
      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :ignore_integrity_errors => false)
      @instance = @class.new
    end

    it "should raise an error if the image fails an integrity check" do
      @uploader.class_eval do
        def extension_white_list
          %(txt)
        end
      end
      running {
        @instance.image = stub_file('test.jpg')
      }.should raise_error(CarrierWave::IntegrityError)
    end

  end

  describe '#mount_uploader with :ignore_processing_errors => false' do
   
    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      
      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :ignore_processing_errors => false)
      @instance = @class.new
    end

    it "should raise an error if the image fails to be processed" do
      @uploader.class_eval do
        process :monkey
        def monkey
          raise CarrierWave::ProcessingError, "Ohh noez!"
        end
      end
      running {
        @instance.image = stub_file('test.jpg')
      }.should raise_error(CarrierWave::ProcessingError)
    end

  end

  describe '#mount_uploader with :mount_on => :monkey' do

  
    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :mount_on => :monkey)
      @instance = @class.new
    end

    describe '#image' do
      it "should retrieve a file from the storage if a value is stored in the database" do
        @instance.should_receive(:read_uploader).at_least(:once).with(:monkey).twice.and_return('test.jpg')
        @instance.image.should be_an_instance_of(@uploader)
        @instance.image.current_path.should == public_path('uploads/test.jpg')
      end
    end

    describe '#write_image_identifier' do
      it "should write to the given column" do
        @instance.should_receive(:write_uploader).with(:monkey, "test.jpg")
        @instance.image = stub_file('test.jpg')
        @instance.write_image_identifier
      end

      it "should remove from the given column when remove_image is true" do
        @instance.image = stub_file('test.jpg')
        @instance.store_image!
        @instance.remove_image = true
        @instance.should_receive(:write_uploader).with(:monkey, "")
        @instance.write_image_identifier
      end
    end
  end

end
