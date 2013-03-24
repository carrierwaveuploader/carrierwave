# encoding: utf-8

require 'spec_helper'
require 'mime/types'

describe CarrierWave::SanitizedFile do

  before do
    FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
  end

  after(:all) do
    if File.exists?(file_path('llama.jpg'))
      FileUtils.rm(file_path('llama.jpg'))
    end
    FileUtils.rm_rf(public_path)
  end

  describe '#empty?' do

    it "should be empty for nil" do
      @sanitized_file = CarrierWave::SanitizedFile.new(nil)
      @sanitized_file.should be_empty
    end

    it "should be empty for an empty string" do
      @sanitized_file = CarrierWave::SanitizedFile.new("")
      @sanitized_file.should be_empty
    end

    it "should be empty for an empty StringIO" do
      @sanitized_file = CarrierWave::SanitizedFile.new(StringIO.new(""))
      @sanitized_file.should be_empty
    end

  end

  describe '#original_filename' do
    it "should default to the original_filename" do
      file = mock('file', :original_filename => 'llama.jpg')
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      sanitized_file.original_filename.should == "llama.jpg"
    end

    it "should defer to the base name of the path if original_filename is unavailable" do
      file = mock('file', :path => '/path/to/test.jpg')
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      sanitized_file.original_filename.should == "test.jpg"
    end

    it "should be nil otherwise" do
      file = mock('file')
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      sanitized_file.original_filename.should be_nil
    end
  end

  describe '#basename' do
    it "should return the basename for complicated extensions" do
      @sanitized_file = CarrierWave::SanitizedFile.new(file_path('complex.filename.tar.gz'))
      @sanitized_file.basename.should == "complex.filename"
    end

    it "should be the filename if the file has no extension" do
      @sanitized_file = CarrierWave::SanitizedFile.new(file_path('complex'))
      @sanitized_file.basename.should == "complex"
    end
  end

  describe '#extension' do
    %w[gz bz2 z lz xz].each do |ext|
      it "should return the extension for complicated extensions (tar.#{ext})" do
        @sanitized_file = CarrierWave::SanitizedFile.new(file_path("complex.filename.tar.#{ext}"))
        @sanitized_file.extension.should == "tar.#{ext}"
      end
    end

    it "should return the extension for real-world user file names" do
      @sanitized_file = CarrierWave::SanitizedFile.new(file_path('Photo on 2009-12-01 at 11.12.jpg'))
      @sanitized_file.extension.should == "jpg"
    end

    it "should return the extension for basic filenames" do
      @sanitized_file = CarrierWave::SanitizedFile.new(file_path('something.png'))
      @sanitized_file.extension.should == "png"
    end

    it "should be an empty string if the file has no extension" do
      @sanitized_file = CarrierWave::SanitizedFile.new(file_path('complex'))
      @sanitized_file.extension.should == ""
    end
  end

  describe '#filename' do

    before do
      @sanitized_file = CarrierWave::SanitizedFile.new(nil)
    end

    it "should default to the original filename if it is valid" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("llama.jpg")
      @sanitized_file.filename.should == "llama.jpg"
    end

    it "should remove illegal characters from a filename" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("test-s,%&m#st?.jpg")
      @sanitized_file.filename.should == "test-s___m_st_.jpg"
    end

    it "should remove slashes from the filename" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("../../very_tricky/foo.bar")
      @sanitized_file.filename.should_not =~ /[\\\/]/
    end

    it "should remove illegal characters if there is no extension" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return('`*foo')
      @sanitized_file.filename.should == "__foo"
    end

    it "should remove the path prefix on Windows" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return('c:\temp\foo.txt')
      @sanitized_file.filename.should == "foo.txt"
    end

    it "should make sure the *nix directory thingies can't be used as filenames" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return(".")
      @sanitized_file.filename.should == "_."
    end

    it "should maintain uppercase filenames" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("DSC4056.JPG")
      @sanitized_file.filename.should == "DSC4056.JPG"
    end

  end

  describe '#filename with an overridden sanitize_regexp' do

    before do
      @sanitized_file = CarrierWave::SanitizedFile.new(nil)
      @sanitized_file.stub(:sanitize_regexp).and_return(/[^a-zA-Z\.\-\+_]/)
    end

    it "should default to the original filename if it is valid" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("llama.jpg")
      @sanitized_file.filename.should == "llama.jpg"
    end

    it "should remove illegal characters from a filename" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("123.jpg")
      @sanitized_file.filename.should == "___.jpg"
    end

  end

  describe '#some unicode filenames with an overridden sanitize_regexp' do

    before do
      @sanitized_file = CarrierWave::SanitizedFile.new(nil)
      regexp = RUBY_VERSION >= '1.9' ? Regexp.new('[^[:word:]\.\-\+]') : /[^éôёЁа-яА-Яa-zA-Zà-üÀ-Ü0-9\.\-\+_]/u
      @sanitized_file.stub(:sanitize_regexp).and_return(regexp)
    end

    it "should default to the original filename if it is valid" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("тестовый.jpg")
      @sanitized_file.filename.should == "тестовый.jpg"
    end

    it "should downcase characters properly" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("ТестоВый Ёжик.jpg")
      @sanitized_file.filename.should == "ТестоВый_Ёжик.jpg"
    end

    it "should remove illegal characters from a filename" do
      @sanitized_file.should_receive(:original_filename).at_least(:once).and_return("⟲«Du côté des chars lourds»_123.doc")
      @sanitized_file.filename.should == "__Du_côté_des_chars_lourds__123.doc"
    end

  end

  describe "#content_type" do
    it "preserves file's content_type" do
      @sanitized_file = CarrierWave::SanitizedFile.new(:content_type => 'image/png')
      @sanitized_file.content_type.should == 'image/png'
    end

    it "should handle Mime::Type object" do
      @file = File.open(file_path('sponsored.doc'))
      @file.stub!(:content_type).and_return(MIME::Type.new('application/msword'))
      @sanitized_file = CarrierWave::SanitizedFile.new(@file)
      @sanitized_file.stub!(:file).and_return(@file)
      lambda { @sanitized_file.content_type }.should_not raise_error
      @sanitized_file.content_type.should == 'application/msword'
    end
  end

  describe "#content_type=" do
    it "sets content_type" do
      @sanitized_file = CarrierWave::SanitizedFile.new(:content_type => 'image/png')
      @sanitized_file.content_type = 'text/html'
      @sanitized_file.content_type.should == 'text/html'
    end
  end

  shared_examples_for "all valid sanitized files" do

    describe '#empty?' do
      it "should not be empty" do
        @sanitized_file.should_not be_empty
      end
    end

    describe '#original_filename' do
      it "should return the original filename" do
        @sanitized_file.original_filename.should == "llama.jpg"
      end
    end

    describe '#filename' do
      it "should return the filename" do
        @sanitized_file.filename.should == "llama.jpg"
      end
    end

    describe '#basename' do
      it "should return the basename" do
        @sanitized_file.basename.should == "llama"
      end
    end

    describe '#extension' do
      it "should return the extension" do
        @sanitized_file.extension.should == "jpg"
      end
    end

    describe "#read" do
      it "should return the contents of the file" do
        @sanitized_file.read.should == "this is stuff"
      end
    end

    describe "#size" do
      it "should return the size of the file" do
        @sanitized_file.size.should == 13
      end
    end

    describe '#move_to' do

      after do
        FileUtils.rm_f(file_path('gurr.png'))
      end

      it "should be moved to the correct location" do
        @sanitized_file.move_to(file_path('gurr.png'))

        File.exists?( file_path('gurr.png') ).should be_true
      end

      it "should have changed its path when moved" do
        @sanitized_file.move_to(file_path('gurr.png'))
        @sanitized_file.path.should == file_path('gurr.png')
      end

      it "should have changed its filename when moved" do
        @sanitized_file.move_to(file_path('gurr.png'))
        @sanitized_file.filename.should == 'gurr.png'
      end

      it "should have changed its basename when moved" do
        @sanitized_file.move_to(file_path('gurr.png'))
        @sanitized_file.basename.should == 'gurr'
      end

      it "should have changed its extension when moved" do
        @sanitized_file.move_to(file_path('gurr.png'))
        @sanitized_file.extension.should == 'png'
      end

      it "should set the right permissions" do
        @sanitized_file.move_to(file_path('gurr.png'), 0755)
        @sanitized_file.should have_permissions(0755)
      end

      it "should set the right directory permissions" do
        @sanitized_file.move_to(file_path('new_dir','gurr.png'), nil, 0775)
        @sanitized_file.should have_directory_permissions(0775)
        FileUtils.rm_rf(file_path('new_dir'))
      end

      it "should return itself" do
        @sanitized_file.move_to(file_path('gurr.png')).should == @sanitized_file
      end

    end

    describe '#copy_to' do

      after do
        FileUtils.rm_f(file_path('gurr.png'))
      end

      it "should be copied to the correct location" do
        @sanitized_file.copy_to(file_path('gurr.png'))

        File.exists?( file_path('gurr.png') ).should be_true

        file_path('gurr.png').should be_identical_to(file_path('llama.jpg'))
      end

      it "should not have changed its path when copied" do
        running { @sanitized_file.copy_to(file_path('gurr.png')) }.should_not change(@sanitized_file, :path)
      end

      it "should not have changed its filename when copied" do
        running { @sanitized_file.copy_to(file_path('gurr.png')) }.should_not change(@sanitized_file, :filename)
      end

      it "should return an object of the same class when copied" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'))
        new_file.should be_an_instance_of(@sanitized_file.class)
      end

      it "should adjust the path of the object that is returned when copied" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'))
        new_file.path.should == file_path('gurr.png')
      end

      it "should adjust the filename of the object that is returned when copied" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'))
        new_file.filename.should == 'gurr.png'
      end

      it "should adjust the basename of the object that is returned when copied" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'))
        new_file.basename.should == 'gurr'
      end

      it "should adjust the extension of the object that is returned when copied" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'))
        new_file.extension.should == 'png'
      end

      it "should set the right permissions" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'), 0755)
        new_file.should have_permissions(0755)
      end

      it "should set the right directory permissions" do
        new_file = @sanitized_file.copy_to(file_path('new_dir', 'gurr.png'), nil, 0755)
        new_file.should have_directory_permissions(0755)
        FileUtils.rm_rf(file_path('new_dir'))
      end

      it "should preserve the file's content type" do
        new_file = @sanitized_file.copy_to(file_path('gurr.png'))
        new_file.content_type.should == @sanitized_file.content_type
      end

    end

  end

  shared_examples_for "all valid sanitized files that are stored on disk" do
    describe '#move_to' do
      it "should not raise an error when moved to its own location" do
        running { @sanitized_file.move_to(@sanitized_file.path) }.should_not raise_error
      end

      it "should remove the original file" do
        original_path = @sanitized_file.path
        @sanitized_file.move_to(public_path('blah.txt'))
        File.exist?(original_path).should be_false
      end
    end

    describe '#copy_to' do
      it "should return a new instance when copied to its own location" do
        running {
          new_file = @sanitized_file.copy_to(@sanitized_file.path)
          new_file.should be_an_instance_of(@sanitized_file.class)
        }.should_not raise_error
      end

      it "should not remove the original file" do
        new_file = @sanitized_file.copy_to(public_path('blah.txt'))
        File.exist?(@sanitized_file.path).should be_true
        File.exist?(new_file.path).should be_true
      end
    end

    describe '#exists?' do
      it "should be true" do
        @sanitized_file.exists?.should be_true
      end
    end

    describe '#delete' do
      it "should remove it from the filesystem" do
        File.exists?(@sanitized_file.path).should be_true
        @sanitized_file.delete
        File.exists?(@sanitized_file.path).should be_false
      end
    end

    describe '#to_file' do
      it "should return a File object" do
        @sanitized_file.to_file.should be_a(File)
      end

      it "should have the same path as the SanitizedFile" do
        @sanitized_file.to_file.path.should == @sanitized_file.path
      end

      it "should have the same contents as the SantizedFile" do
        @sanitized_file.to_file.read.should == @sanitized_file.read
      end
    end
  end

  shared_examples_for "all valid sanitized files that are read from an IO object" do

    describe '#read' do
      it "should have an open IO object" do
        @sanitized_file.instance_variable_get(:@file).closed?.should be_false
      end

      it "should close the IO object after reading" do
        @sanitized_file.read
        @sanitized_file.instance_variable_get(:@file).closed?.should be_true
      end
    end
  end

  describe "with a valid Hash" do
    before do
      @hash = {
        "tempfile" => stub_merb_tempfile('llama.jpg'),
        "filename" => "llama.jpg",
        "content_type" => 'image/jpeg'
      }
      @sanitized_file = CarrierWave::SanitizedFile.new(@hash)
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe '#path' do
      it "should return the path of the tempfile" do
        @sanitized_file.path.should_not be_nil
        @sanitized_file.path.should == @hash["tempfile"].path
      end
    end

    describe '#is_path?' do
      it "should be false" do
        @sanitized_file.is_path?.should be_false
      end
    end

  end

  describe "with a valid Tempfile" do
    before do
      @tempfile = stub_tempfile('llama.jpg', 'image/jpeg')
      @sanitized_file = CarrierWave::SanitizedFile.new(@tempfile)
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe '#is_path?' do
      it "should be false" do
        @sanitized_file.is_path?.should be_false
      end
    end

    describe '#path' do
      it "should return the path of the tempfile" do
        @sanitized_file.path.should_not be_nil
        @sanitized_file.path.should == @tempfile.path
      end
    end

  end

  describe "with a valid StringIO" do
    before do
      @sanitized_file = CarrierWave::SanitizedFile.new(stub_stringio('llama.jpg', 'image/jpeg'))
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe '#exists?' do
      it "should be false" do
        @sanitized_file.exists?.should be_false
      end
    end

    describe '#is_path?' do
      it "should be false" do
        @sanitized_file.is_path?.should be_false
      end
    end

    describe '#path' do
      it "should be nil" do
        @sanitized_file.path.should be_nil
      end
    end

    describe '#delete' do
      it "should not raise an error" do
        running { @sanitized_file.delete }.should_not raise_error
      end
    end

    describe '#to_file' do
      it "should be nil" do
        @sanitized_file.to_file.should be_nil
      end
    end

  end

  describe "with a valid File object" do
    before do
      FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
      @sanitized_file = CarrierWave::SanitizedFile.new(stub_file('llama.jpg', 'image/jpeg'))
      @sanitized_file.should_not be_empty
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe '#is_path?' do
      it "should be false" do
        @sanitized_file.is_path?.should be_false
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        @sanitized_file.path.should_not be_nil
        @sanitized_file.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "with a valid File object and an empty file" do
    before do
      FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
      FileUtils.rm file_path('llama.jpg')
      FileUtils.touch file_path('llama.jpg')
      @sanitized_file = CarrierWave::SanitizedFile.new(stub_file('llama.jpg', 'image/jpeg'))
      @sanitized_file.should_not be_empty
    end

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe '#is_path?' do
      it "should be false" do
        @sanitized_file.is_path?.should be_false
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        @sanitized_file.path.should_not be_nil
        @sanitized_file.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "with a valid path" do
    before do
      FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
      @sanitized_file = CarrierWave::SanitizedFile.new(file_path('llama.jpg'))
      @sanitized_file.should_not be_empty
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#is_path?' do
      it "should be true" do
        @sanitized_file.is_path?.should be_true
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        @sanitized_file.path.should_not be_nil
        @sanitized_file.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "with a valid Pathname" do
    before do
      FileUtils.copy_file(file_path('test.jpg'), file_path('llama.jpg'))
      @sanitized_file = CarrierWave::SanitizedFile.new(Pathname.new(file_path('llama.jpg')))
      @sanitized_file.should_not be_empty
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#is_path?' do
      it "should be true" do
        @sanitized_file.is_path?.should be_true
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        @sanitized_file.path.should_not be_nil
        @sanitized_file.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "that is empty" do
    before do
      @empty = CarrierWave::SanitizedFile.new(nil)
    end

    describe '#empty?' do
      it "should be true" do
        @empty.should be_empty
      end
    end

    describe '#exists?' do
      it "should be false" do
        @empty.exists?.should be_false
      end
    end

    describe '#is_path?' do
      it "should be false" do
        @empty.is_path?.should be_false
      end
    end

    describe '#size' do
      it "should be zero" do
        @empty.size.should be_zero
      end
    end

    describe '#path' do
      it "should be nil" do
        @empty.path.should be_nil
      end
    end

    describe '#original_filename' do
      it "should be nil" do
        @empty.original_filename.should be_nil
      end
    end

    describe '#filename' do
      it "should be nil" do
        @empty.filename.should be_nil
      end
    end

    describe '#basename' do
      it "should be nil" do
        @empty.basename.should be_nil
      end
    end

    describe '#extension' do
      it "should be nil" do
        @empty.extension.should be_nil
      end
    end

    describe '#delete' do
      it "should not raise an error" do
        running { @empty.delete }.should_not raise_error
      end
    end

    describe '#to_file' do
      it "should be nil" do
        @empty.to_file.should be_nil
      end
    end
  end

  describe "that is an empty string" do
    before do
      @empty = CarrierWave::SanitizedFile.new("")
    end

    describe '#empty?' do
      it "should be true" do
        @empty.should be_empty
      end
    end

    describe '#exists?' do
      it "should be false" do
        @empty.exists?.should be_false
      end
    end

    describe '#is_path?' do
      it "should be false" do
        @empty.is_path?.should be_false
      end
    end

    describe '#size' do
      it "should be zero" do
        @empty.size.should be_zero
      end
    end

    describe '#path' do
      it "should be nil" do
        @empty.path.should be_nil
      end
    end

    describe '#original_filename' do
      it "should be nil" do
        @empty.original_filename.should be_nil
      end
    end

    describe '#filename' do
      it "should be nil" do
        @empty.filename.should be_nil
      end
    end

    describe '#basename' do
      it "should be nil" do
        @empty.basename.should be_nil
      end
    end

    describe '#extension' do
      it "should be nil" do
        @empty.extension.should be_nil
      end
    end

    describe '#delete' do
      it "should not raise an error" do
        running { @empty.delete }.should_not raise_error
      end
    end

    describe '#to_file' do
      it "should be nil" do
        @empty.to_file.should be_nil
      end
    end
  end

end
