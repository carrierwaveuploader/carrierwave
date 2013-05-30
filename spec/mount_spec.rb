# encoding: utf-8

require 'spec_helper'

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

    it "should allow marshalling uploaders and versions" do
      Object.const_set("MyClass#{@class.object_id}".gsub('-', '_'), @class)
      Object.const_set("Uploader#{@uploader.object_id}".gsub('-', '_'), @uploader)
      @uploader.class_eval do
        def rotate
        end
      end
      @uploader.version :thumb do
        process :rotate
      end
      @instance.image = stub_file('test.jpg')
      lambda { Marshal.dump @instance.image }.should_not raise_error
    end

    describe "expected behavior with subclassed uploaders" do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @uploader1 = Class.new(CarrierWave::Uploader::Base)
        @uploader1.process :rotate
        @uploader1.version :thumb do
          process :compress
        end
        @uploader2 = Class.new(@uploader1)
        @uploader2.process :shrink
        @uploader2.version :secret do
          process :encrypt
        end
        @class.mount_uploader(:image1, @uploader1)
        @class.mount_uploader(:image2, @uploader2)
        @instance = @class.new
      end

      it "should inherit defined versions" do
        @instance.image1.should respond_to(:thumb)
        @instance.image2.should respond_to(:thumb)
      end

      it "should not inherit versions defined in subclasses" do
        @instance.image1.should_not respond_to(:secret)
        @instance.image2.should respond_to(:secret)
      end

      it "should inherit defined processors properly" do
        @uploader1.processors.should == [[:rotate, [], nil]]
        @uploader2.processors.should == [[:rotate, [], nil], [:shrink, [], nil]]
        @uploader1.versions[:thumb][:uploader].processors.should == [[:compress, [], nil]]
        @uploader2.versions[:thumb][:uploader].processors.should == [[:compress, [], nil]]
        @uploader2.versions[:secret][:uploader].processors.should == [[:encrypt, [], nil]]
      end
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

      it "should fail silently if the image fails a white list integrity check" do
        @uploader.class_eval do
          def extension_white_list
            %w(txt)
          end
        end
        @instance.image = stub_file('test.jpg')
        @instance.image.should be_blank
      end

      it "should fail silently if the image fails a black list integrity check" do
        @uploader.class_eval do
          def extension_black_list
            %w(jpg)
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
        @instance.image_cache.should =~ %r(^[\d]+\-[\d]+\-[\d]{4}/test\.jpg$)
      end

    end

    describe '#image_cache=' do

      before do
        @instance.stub!(:write_uploader)
        @instance.stub!(:read_uploader).and_return(nil)
        CarrierWave::SanitizedFile.new(file_path('test.jpg')).copy_to(public_path('uploads/tmp/1369894322-123-1234/test.jpg'))
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
        @instance.image_cache = '1369894322-123-1234/test.jpg'
        @instance.image.current_path.should == public_path('uploads/tmp/1369894322-123-1234/test.jpg')
      end

      it "should not write over a previously assigned file" do
        @instance.image = stub_file('test.jpg')
        @instance.image_cache = '1369894322-123-1234/monkey.jpg'
        @instance.image.current_path.should =~ /test.jpg$/
      end
    end

    describe 'with ShamRack' do

      before do
        sham_rack_app = ShamRack.at('www.example.com').stub
        sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      end

      after do
        ShamRack.unmount_all
      end

      describe '#remote_image_url' do
        it "should return nil" do
          @instance.remote_image_url.should be_nil
        end

        it "should return previously cached URL" do
          @instance.remote_image_url = 'http://www.example.com/test.jpg'
          @instance.remote_image_url.should == 'http://www.example.com/test.jpg'
        end
      end

      describe '#remote_image_url=' do

        it "should do nothing when nil is assigned" do
          @instance.remote_image_url = nil
          @instance.image.should be_blank
        end

        it "should do nothing when an empty string is assigned" do
          @instance.remote_image_url = ''
          @instance.image.should be_blank
        end

        it "retrieve from cache when a cache name is assigned" do
          @instance.remote_image_url = 'http://www.example.com/test.jpg'
          @instance.image.current_path.should =~ /test.jpg$/
        end

        it "should write over a previously assigned file" do
          @instance.image = stub_file('portrait.jpg')
          @instance.remote_image_url = 'http://www.example.com/test.jpg'
          @instance.image.current_path.should =~ /test.jpg$/
        end
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

      describe "when an integrity check fails" do
        before do
          @uploader.class_eval do
            def extension_white_list
              %w(txt)
            end
          end
        end

        it "should be an error instance if file was cached" do
          @instance.image = stub_file('test.jpg')
          e = @instance.image_integrity_error
          e.should be_an_instance_of(CarrierWave::IntegrityError)
          e.message.lines.grep(/^You are not allowed to upload/).should be_true
        end

        it "should be an error instance if file was downloaded" do
          sham_rack_app = ShamRack.at('www.example.com').stub
          sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')

          @instance.remote_image_url = "http://www.example.com/test.jpg"
          e = @instance.image_integrity_error
          e.should be_an_instance_of(CarrierWave::IntegrityError)
          e.message.lines.grep(/^You are not allowed to upload/).should be_true
        end
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

      describe "when an processing error occurs" do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError, "Ohh noez!"
            end
          end
        end

        it "should be an error instance if file was cached" do
          @instance.image = stub_file('test.jpg')
          @instance.image_processing_error.should be_an_instance_of(CarrierWave::ProcessingError)
        end

        it "should be an error instance if file was downloaded" do
          sham_rack_app = ShamRack.at('www.example.com').stub
          sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')

          @instance.remote_image_url = "http://www.example.com/test.jpg"
          @instance.image_processing_error.should be_an_instance_of(CarrierWave::ProcessingError)
        end
      end
    end

    describe '#image_download_error' do
      before do
        sham_rack_app = ShamRack.at('www.example.com').stub
        sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      end

      it "should be nil by default" do
        @instance.image_download_error.should be_nil
      end

      it "should be nil if file download was successful" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"
        @instance.image_download_error.should be_nil
      end

      it "should be an error instance if file could not be found" do
        @instance.remote_image_url = "http://www.example.com/missing.jpg"
        @instance.image_download_error.should be_an_instance_of(CarrierWave::DownloadError)
      end
    end

    describe '#image_download_error' do
      before do
        sham_rack_app = ShamRack.at('www.example.com').stub
        sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')
      end

      it "should be nil by default" do
        @instance.image_download_error.should be_nil
      end

      it "should be nil if file download was successful" do
        @instance.remote_image_url = "http://www.example.com/test.jpg"
        @instance.image_download_error.should be_nil
      end

      it "should be an error instance if file could not be found" do
        @instance.remote_image_url = "http://www.example.com/missing.jpg"
        @instance.image_download_error.should be_an_instance_of(CarrierWave::DownloadError)
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

    describe '#image_identifier' do
      it "should return the identifier from the mounted column" do
        @instance.should_receive(:read_uploader).with(:image).and_return("test.jpg")
        @instance.image_identifier.should == 'test.jpg'
      end
    end

  end

  describe '#mount_uploader without an uploader' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)
      @class.mount_uploader(:image)
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

    end

  end

  describe '#mount_uploader with a block' do
    describe 'and no uploader given' do
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

      it "should return an instance of a subclass of CarrierWave::Uploader::Base" do
        @instance.image.should be_a(CarrierWave::Uploader::Base)
      end

      it "should apply any custom modifications" do
        @instance.image.monkey.should == "blah"
      end
    end

    describe 'and an uploader given' do
      before do
        @class = Class.new
        @class.send(:extend, CarrierWave::Mount)
        @uploader = Class.new(CarrierWave::Uploader::Base)
        @uploader.version :thumb do
          version :mini
          version :maxi
        end
        @class.mount_uploader(:image, @uploader) do
          def fish
            'blub'
          end
        end
        @instance = @class.new
      end

      it "should return an instance of the uploader specified" do
        @instance.image.should be_a_kind_of(@uploader)
      end

      it "should apply any custom modifications to the instance" do
        @instance.image.fish.should == "blub"
      end

      it "should apply any custom modifications to all defined versions" do
        @instance.image.thumb.fish.should == "blub"
        @instance.image.thumb.mini.fish.should == "blub"
        @instance.image.thumb.maxi.fish.should == "blub"
      end

      it "should not apply any custom modifications to the uploader class" do
        @uploader.new.should_not respond_to(:fish)
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

      @uploader.class_eval do
        def extension_white_list
          %w(txt)
        end
      end
    end

    it "should raise an error if the image fails an integrity check when cached" do
      running {
        @instance.image = stub_file('test.jpg')
      }.should raise_error(CarrierWave::IntegrityError)
    end

    it "should raise an error if the image fails an integrity check when downloaded" do
      sham_rack_app = ShamRack.at('www.example.com').stub
      sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')

      running {
        @instance.remote_image_url = "http://www.example.com/test.jpg"
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

      @uploader.class_eval do
        process :monkey
        def monkey
          raise CarrierWave::ProcessingError, "Ohh noez!"
        end
      end
    end

    it "should raise an error if the image fails to be processed when cached" do
      running {
        @instance.image = stub_file('test.jpg')
      }.should raise_error(CarrierWave::ProcessingError)
    end

    it "should raise an error if the image fails to be processed when downloaded" do
      sham_rack_app = ShamRack.at('www.example.com').stub
      sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'image/jpg')

      running {
        @instance.remote_image_url = "http://www.example.com/test.jpg"
      }.should raise_error(CarrierWave::ProcessingError)
    end

  end

  describe '#mount_uploader with :ignore_download_errors => false' do

    before do
      @class = Class.new
      @class.send(:extend, CarrierWave::Mount)

      @uploader = Class.new(CarrierWave::Uploader::Base)

      @class.mount_uploader(:image, @uploader, :ignore_download_errors => false)
      @instance = @class.new
    end

    it "should raise an error if the image fails to be processed" do
      @uploader.class_eval do
        def download! uri
          raise CarrierWave::DownloadError
        end
      end

      running {
        @instance.remote_image_url = "http://www.example.com/test.jpg"
      }.should raise_error(CarrierWave::DownloadError)
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
        @instance.should_receive(:read_uploader).at_least(:once).with(:monkey).and_return('test.jpg')
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
