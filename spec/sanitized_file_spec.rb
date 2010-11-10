# encoding: utf-8

require 'spec_helper'

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
      subject = CarrierWave::SanitizedFile.new(nil)
      subject.should be_empty
    end

    it "should be empty for an empty string" do
      subject = CarrierWave::SanitizedFile.new("")
      subject.should be_empty
    end

    it "should be empty for an empty StringIO" do
      subject = CarrierWave::SanitizedFile.new(StringIO.new(""))
      subject.should be_empty
    end

    it "should be empty for a file with a zero size" do
      FileUtils.rm file_path('llama.jpg')
      FileUtils.touch file_path('llama.jpg')

      subject = CarrierWave::SanitizedFile.new(File.open(file_path('llama.jpg')))
      subject.should be_empty
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
      subject = CarrierWave::SanitizedFile.new(file_path('complex.filename.tar.gz'))
      subject.basename.should == "complex.filename"
    end

    it "should be the filename if the file has no extension" do
      subject = CarrierWave::SanitizedFile.new(file_path('complex'))
      subject.basename.should == "complex"
    end
  end

  describe '#extension' do
    it "should return the extension for complicated extensions" do
      subject = CarrierWave::SanitizedFile.new(file_path('complex.filename.tar.gz'))
      subject.extension.should == "tar.gz"
    end

    it "should return the extension for real-world user file names" do
      subject = CarrierWave::SanitizedFile.new(file_path('Photo on 2009-12-01 at 11.12.jpg'))
      subject.extension.should == "jpg"
    end

    it "should return the extension for basic filenames" do
      subject = CarrierWave::SanitizedFile.new(file_path('something.png'))
      subject.extension.should == "png"
    end

    it "should be an empty string if the file has no extension" do
      subject = CarrierWave::SanitizedFile.new(file_path('complex'))
      subject.extension.should == ""
    end
  end

  describe '#filename' do
    subject{ CarrierWave::SanitizedFile.new(nil) }

    it "should default to the original filename if it is valid" do
      subject.should_receive(:original_filename).at_least(:once).and_return("llama.jpg")
      subject.filename.should == "llama.jpg"
    end

    it "should remove illegal characters from a filename" do
      subject.should_receive(:original_filename).at_least(:once).and_return("test-s,%&m#st?.jpg")
      subject.filename.should == "test-s___m_st_.jpg"
    end

    it "should remove slashes from the filename" do
      subject.should_receive(:original_filename).at_least(:once).and_return("../../very_tricky/foo.bar")
      subject.filename.should_not =~ /[\\\/]/
    end

    it "should remove illegal characters if there is no extension" do
      subject.should_receive(:original_filename).at_least(:once).and_return('`*foo')
      subject.filename.should == "__foo"
    end

    it "should remove the path prefix on Windows" do
      subject.should_receive(:original_filename).at_least(:once).and_return('c:\temp\foo.txt')
      subject.filename.should == "foo.txt"
    end

    it "should make sure the *nix directory thingies can't be used as filenames" do
      subject.should_receive(:original_filename).at_least(:once).and_return(".")
      subject.filename.should == "_."
    end

    it "should downcase uppercase filenames" do
      subject.should_receive(:original_filename).at_least(:once).and_return("DSC4056.JPG")
      subject.filename.should == "dsc4056.jpg"
    end

  end

  shared_examples_for "all valid sanitized files" do

    describe '#empty?' do
      it { should_not be_empty }
    end

    describe '#original_filename' do
      its(:original_filename) { should == 'llama.jpg' }
    end

    describe '#filename' do
      its(:filename) { should == 'llama.jpg' }
    end

    describe '#basename' do
      its(:basename) { should == 'llama' }
    end

    describe '#extension' do
      its(:extension) { should == 'jpg' }
    end

    describe "#read" do
      it "should return the contents of the file" do
        subject.read.should == "this is stuff"
      end
    end

    describe "#size" do
      its(:size) { should == 13 }
    end

    describe '#move_to' do

      after do
        FileUtils.rm(file_path('gurr.png'))
      end

      it "should be moved to the correct location" do
        subject.move_to(file_path('gurr.png'))

        File.exists?( file_path('gurr.png') ).should be_true
      end

      it "should have changed its path when moved" do
        subject.move_to(file_path('gurr.png'))
        subject.path.should == file_path('gurr.png')
      end

      it "should have changed its filename when moved" do
        subject.move_to(file_path('gurr.png'))
        subject.filename.should == 'gurr.png'
      end

      it "should have changed its basename when moved" do
        subject.move_to(file_path('gurr.png'))
        subject.basename.should == 'gurr'
      end

      it "should have changed its extension when moved" do
        subject.move_to(file_path('gurr.png'))
        subject.extension.should == 'png'
      end

      it "should set the right permissions" do
        subject.move_to(file_path('gurr.png'), 0755)
        subject.should have_permissions(0755)
      end

    end

    describe '#copy_to' do

      after do
        FileUtils.rm(file_path('gurr.png'))
      end

      it "should be copied to the correct location" do
        subject.copy_to(file_path('gurr.png'))

        File.exists?( file_path('gurr.png') ).should be_true

        file_path('gurr.png').should be_identical_to(file_path('llama.jpg'))
      end

      it "should not have changed its path when copied" do
        running { subject.copy_to(file_path('gurr.png')) }.should_not change(subject, :path)
      end

      it "should not have changed its filename when copied" do
        running { subject.copy_to(file_path('gurr.png')) }.should_not change(subject, :filename)
      end

      it "should return an object of the same class when copied" do
        new_file = subject.copy_to(file_path('gurr.png'))
        new_file.should be_an_instance_of(subject.class)
      end

      it "should adjust the path of the object that is returned when copied" do
        new_file = subject.copy_to(file_path('gurr.png'))
        new_file.path.should == file_path('gurr.png')
      end

      it "should adjust the filename of the object that is returned when copied" do
        new_file = subject.copy_to(file_path('gurr.png'))
        new_file.filename.should == 'gurr.png'
      end

      it "should adjust the basename of the object that is returned when copied" do
        new_file = subject.copy_to(file_path('gurr.png'))
        new_file.basename.should == 'gurr'
      end

      it "should adjust the extension of the object that is returned when copied" do
        new_file = subject.copy_to(file_path('gurr.png'))
        new_file.extension.should == 'png'
      end

      it "should set the right permissions" do
        new_file = subject.copy_to(file_path('gurr.png'), 0755)
        new_file.should have_permissions(0755)
      end
      
      it "should preserve the file's content type" do
        new_file = subject.copy_to(file_path('gurr.png'))
        new_file.content_type.should ==(subject.content_type)
      end

    end

  end

  shared_examples_for "all valid sanitized files that are stored on disk" do
    describe '#move_to' do
      it "should not raise an error when moved to its own location" do
        running { subject.move_to(subject.path) }.should_not raise_error
      end

      it "should remove the original file" do
        original_path = subject.path
        subject.move_to(public_path('blah.txt'))
        File.exist?(original_path).should be_false
      end
    end

    describe '#copy_to' do
      it "should return a new instance when copied to its own location" do
        running {
          new_file = subject.copy_to(subject.path)
          new_file.should be_an_instance_of(subject.class)
        }.should_not raise_error
      end

      it "should not remove the original file" do
        new_file = subject.copy_to(public_path('blah.txt'))
        File.exist?(subject.path).should be_true
        File.exist?(new_file.path).should be_true
      end
    end

    describe '#exists?' do
      it "should be true" do
        subject.exists?.should be_true
      end
    end

    describe '#delete' do
      it "should remove it from the filesystem" do
        File.exists?(subject.path).should be_true
        subject.delete
        File.exists?(subject.path).should be_false
      end
    end
  end

  describe "with a valid Hash" do
    let(:hash){ 
      {
        "tempfile" => stub_merb_tempfile('llama.jpg'),
        "filename" => "llama.jpg",
        "content_type" => 'image/jpeg'
      }
    }
    subject{ CarrierWave::SanitizedFile.new(hash) }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#path' do
      it "should return the path of the tempfile" do
        subject.path.should_not be_nil
        subject.path.should == hash["tempfile"].path
      end
    end

    describe '#is_path?' do
      it "should be false" do
        subject.is_path?.should be_false
      end
    end

  end

  describe "with a valid Tempfile" do
    let(:tempfile) { stub_tempfile('llama.jpg', 'image/jpeg') }
    subject{ CarrierWave::SanitizedFile.new(tempfile) }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#is_path?' do
      it "should be false" do
        subject.is_path?.should be_false
      end
    end

    describe '#path' do
      it "should return the path of the tempfile" do
        subject.path.should_not be_nil
        subject.path.should == tempfile.path
      end
    end

  end

  describe "with a valid StringIO" do
    subject {
      CarrierWave::SanitizedFile.new(stub_stringio('llama.jpg', 'image/jpeg'))
    }

    it_should_behave_like "all valid sanitized files"

    describe '#exists?' do
      it "should be false" do
        subject.exists?.should be_false
      end
    end

    describe '#is_path?' do
      it "should be false" do
        subject.is_path?.should be_false
      end
    end

    describe '#path' do
      its(:path) { should be_nil }
    end

    describe '#delete' do
      it "should not raise an error" do
        running { subject.delete }.should_not raise_error
      end
    end

  end

  describe "with a valid File object" do
    subject {
      FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
      CarrierWave::SanitizedFile.new(stub_file('llama.jpg', 'image/jpeg'))
    }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#is_path?' do
      it "should be false" do
        subject.is_path?.should be_false
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        subject.path.should_not be_nil
        subject.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "with a valid path" do
    subject {
      FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
      CarrierWave::SanitizedFile.new(file_path('llama.jpg'))
    }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#is_path?' do
      it "should be true" do
        subject.is_path?.should be_true
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        subject.path.should_not be_nil
        subject.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "with a valid Pathname" do
    subject {
      FileUtils.copy_file(file_path('test.jpg'), file_path('llama.jpg'))
      CarrierWave::SanitizedFile.new(Pathname.new(file_path('llama.jpg')))
    }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe '#is_path?' do
      it "should be true" do
        subject.is_path?.should be_true
      end
    end

    describe '#path' do
      it "should return the path of the file" do
        subject.path.should_not be_nil
        subject.path.should == file_path('llama.jpg')
      end
    end

  end

  describe "that is empty" do
    subject{ CarrierWave::SanitizedFile.new(nil) }

    describe '#empty?' do
      it "should be true" do
        subject.should be_empty
      end
    end

    describe '#exists?' do
      it "should be false" do
        subject.exists?.should be_false
      end
    end

    describe '#is_path?' do
      it "should be false" do
        subject.is_path?.should be_false
      end
    end

    describe '#size' do
      its(:size) { should be_zero }
    end

    describe '#path' do
      its(:path) { should be_nil }
    end

    describe '#original_filename' do
      its(:original_filename) { should be_nil }
    end

    describe '#filename' do
      its(:filename) { should be_nil }
    end

    describe '#basename' do
      its(:basename) { should be_nil }
    end

    describe '#extension' do
      its(:extension) { should be_nil }
    end

    describe '#delete' do
      it "should not raise an error" do
        running { subject.delete }.should_not raise_error
      end
    end
  end

  describe "that is an empty string" do
    subject{ CarrierWave::SanitizedFile.new("") }

    describe '#empty?' do
      it "should be true" do
        subject.should be_empty
      end
    end

    describe '#exists?' do
      it "should be false" do
        subject.exists?.should be_false
      end
    end

    describe '#is_path?' do
      it "should be false" do
        subject.is_path?.should be_false
      end
    end

    describe '#size' do
      its(:size) { should be_zero }
    end

    describe '#path' do
      its(:path) { should be_nil }
    end

    describe '#original_filename' do
      its(:original_filename) { should be_nil }
    end

    describe '#filename' do
      its(:filename) { should be_nil }
    end

    describe '#basename' do
      its(:basename) { should be_nil }
    end

    describe '#extension' do
      its(:extension) { should be_nil }
    end

    describe '#delete' do
      it "should not raise an error" do
        running { subject.delete }.should_not raise_error
      end
    end
  end

end
