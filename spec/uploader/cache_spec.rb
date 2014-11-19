# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    FileUtils.rm_rf(public_path)
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#cache_dir' do
    it "should default to the config option" do
      @uploader.cache_dir.should == 'uploads/tmp'
    end
  end

  describe '#sanitized_file' do
    before do
      @uploader.store! CarrierWave::SanitizedFile.new(File.open(file_path('test.jpg')))
    end

    it "should return a sanitized file" do
      @uploader.sanitized_file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should only read file once" do
      @uploader.file.should_receive(:read).once.and_return('this is stuff')
      @uploader.sanitized_file
    end
  end

  describe '#cache!' do

    before do
      CarrierWave.stub(:generate_cache_id).and_return('1369894322-345-2255')
    end

    it "should cache a file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should be_cached
    end

    it "should store the cache name" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.cache_name.should == '1369894322-345-2255/test.jpg'
    end

    it "should set the filename to the file's sanitized filename" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.filename.should == 'test.jpg'
    end

    it "should move it to the tmp dir" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpg')
      @uploader.file.exists?.should be_true
    end

    it "should set the url" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url.should == '/uploads/tmp/1369894322-345-2255/test.jpg'
    end

    it "should raise an error when trying to cache a string" do
      running {
        @uploader.cache!(file_path('test.jpg'))
      }.should raise_error(CarrierWave::FormNotMultipart)
    end

    it "should raise an error when trying to cache a pathname" do
      running {
        @uploader.cache!(Pathname.new(file_path('test.jpg')))
      }.should raise_error(CarrierWave::FormNotMultipart)
    end

    it "should do nothing when trying to cache an empty file" do
      @uploader.cache!(nil)
    end

    it "should set permissions if options are given" do
      @uploader_class.permissions = 0777

      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should have_permissions(0777)
    end

    it "should set directory permissions if options are given" do
      @uploader_class.directory_permissions = 0777

      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.should have_directory_permissions(0777)
    end

    describe "with ensuring multipart form deactivated" do

      before do
        CarrierWave.configure do |config|
          config.ensure_multipart_form = false
        end
      end

      it "should not raise an error when trying to cache a string" do
        running {
          @uploader.cache!(file_path('test.jpg'))
        }.should_not raise_error
      end

      it "should raise an error when trying to cache a pathname and " do
        running {
          @uploader.cache!(Pathname.new(file_path('test.jpg')))
        }.should_not raise_error
      end

    end

    describe "with the move_to_cache option" do

      before do
        ## make a copy
        file = file_path('test.jpg')
        tmpfile = file_path("test_move.jpeg")
        FileUtils.rm_f(tmpfile)
        FileUtils.cp(file, File.join(File.dirname(file), "test_move.jpeg"))
        @tmpfile = File.open(tmpfile)

        ## stub
        CarrierWave.stub(:generate_cache_id).and_return('1369894322-345-2255')

        @cached_path = public_path('uploads/tmp/1369894322-345-2255/test_move.jpeg')
        @workfile_path = tmp_path('1369894322-345-2255/test_move.jpeg')
        @uploader_class.permissions = 0777
        @uploader_class.directory_permissions = 0777
      end

      after do
        FileUtils.rm_f(@tmpfile.path)
      end

      context "set to true" do
        before do
          @uploader_class.move_to_cache = true
        end

        it "should move it from the upload dir to the tmp dir" do
          original_path = @tmpfile.path
          @uploader.cache!(@tmpfile)
          @uploader.file.path.should == @cached_path
          File.exist?(@cached_path).should be_true
          File.exist?(original_path).should be_false
        end

        it "should use move_to() during cache!()" do
          moved_file = double('moved file').as_null_object
          CarrierWave::SanitizedFile.any_instance.should_receive(:move_to).with(@workfile_path, 0777, 0777).and_return(moved_file)
          moved_file.should_receive(:move_to).with(@cached_path, 0777, 0777, true)
          @uploader.cache!(@tmpfile)
        end

        it "should not use copy_to() during cache!()" do
          CarrierWave::SanitizedFile.any_instance.should_not_receive(:copy_to)
          @uploader.cache!(@tmpfile)
        end
      end

      context "set to false" do
        before do
          @uploader_class.move_to_cache = false
        end

        it "should copy it from the upload dir to the tmp dir" do
          original_path = @tmpfile.path
          @uploader.cache!(@tmpfile)
          @uploader.file.path.should == @cached_path
          File.exist?(@cached_path).should be_true
          File.exist?(original_path).should be_true
        end

        it "should use copy_to() during cache!()" do
          moved_file = double('moved file').as_null_object
          CarrierWave::SanitizedFile.any_instance.should_receive(:copy_to).with(@workfile_path, 0777, 0777).and_return(moved_file)
          moved_file.should_receive(:move_to).with(@cached_path, 0777, 0777, true)
          @uploader.cache!(@tmpfile)
        end

        it "should not use move_to() in moving to temporary location during cache!()" do
          CarrierWave::SanitizedFile.any_instance.should_not_receive(:move_to).with(@workfile_path, 0777, 0777)
          @uploader.cache!(@tmpfile)
        end
      end

    end

    it "should use different workfiles for different versions" do
      @uploader_class.version :small
      @uploader_class.version :large
      @uploader.cache!(File.open(file_path('test.jpg')))
      expect(@uploader.small.send(:workfile_path)).not_to eq @uploader.large.send(:workfile_path)
    end
  end

  describe '#retrieve_from_cache!' do
    it "should cache a file" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.file.should be_an_instance_of(CarrierWave::SanitizedFile)
    end

    it "should be cached" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.should be_cached
    end

    it "should set the path to the tmp dir" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.current_path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpeg')
    end

    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.retrieve_from_cache!('1369894322-345-2255/bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/1369894322-345-2255/bork.txt')
    end

    it "should store the cache_name" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.cache_name.should == '1369894322-345-2255/test.jpeg'
    end

    it "should store the filename" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.filename.should == 'test.jpeg'
    end

    it "should set the url" do
      @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpeg')
      @uploader.url.should == '/uploads/tmp/1369894322-345-2255/test.jpeg'
    end

    it "should raise an error when the cache_id has an invalid format" do
      running {
        @uploader.retrieve_from_cache!('12345/test.jpeg')
      }.should raise_error(CarrierWave::InvalidParameter)

      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end

    it "should raise an error when the original_filename contains invalid characters" do
      running {
        @uploader.retrieve_from_cache!('1369894322-345-2255/te/st.jpeg')
      }.should raise_error(CarrierWave::InvalidParameter)
      running {
        @uploader.retrieve_from_cache!('1369894322-345-2255/te??%st.jpeg')
      }.should raise_error(CarrierWave::InvalidParameter)

      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end
  end

  describe 'with an overridden, reversing, filename' do
    before do
      @uploader_class.class_eval do
        def filename
          super.reverse unless super.blank?
        end
      end
    end

    describe '#cache!' do

      before do
        CarrierWave.stub(:generate_cache_id).and_return('1369894322-345-2255')
      end

      it "should set the filename to the file's reversed filename" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.filename.should == "gpj.tset"
      end

      it "should move it to the tmp dir with the filename unreversed" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.current_path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpg')
        @uploader.file.exists?.should be_true
      end
    end

    describe '#retrieve_from_cache!' do
      it "should set the path to the tmp dir" do
        @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpg')
        @uploader.current_path.should == public_path('uploads/tmp/1369894322-345-2255/test.jpg')
      end

      it "should set the filename to the reversed name of the file" do
        @uploader.retrieve_from_cache!('1369894322-345-2255/test.jpg')
        @uploader.filename.should == "gpj.tset"
      end
    end
  end
  describe '.generate_cache_id' do
    it 'should generate dir name bsed on UTC time' do
      Timecop.travel(Time.at(1369896000)) do
        CarrierWave.generate_cache_id.should match(/\A1369896000-\d+-\d+\Z/)
      end
    end
  end
end
