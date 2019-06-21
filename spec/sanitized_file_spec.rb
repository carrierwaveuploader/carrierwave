require 'spec_helper'

describe CarrierWave::SanitizedFile do
  before do
    FileUtils.cp(file_path('test.jpg'), file_path('llama.jpg'))
  end

  after do
    FileUtils.rm_rf(file_path("new_dir"))
  end

  after(:all) do
    if File.exist?(file_path('llama.jpg'))
      FileUtils.rm(file_path('llama.jpg'))
    end
    FileUtils.rm_rf(public_path)
  end

  describe "#empty?" do
    it "should be empty for nil" do
      sanitized_file = CarrierWave::SanitizedFile.new(nil)

      expect(sanitized_file).to be_empty
    end

    it "should be empty for an empty string" do
      sanitized_file = CarrierWave::SanitizedFile.new("")

      expect(sanitized_file).to be_empty
    end

    it "should be empty for an empty StringIO" do
      sanitized_file = CarrierWave::SanitizedFile.new(StringIO.new(""))

      expect(sanitized_file).to be_empty
    end

  end

  describe '#original_filename' do
    it "should default to the original_filename" do
      file = double('file', :original_filename => 'llama.jpg')
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      expect(sanitized_file.original_filename).to eq("llama.jpg")
    end

    it "should defer to the base name of the path if original_filename is unavailable" do
      file = double('file', :path => '/path/to/test.jpg')
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      expect(sanitized_file.original_filename).to eq("test.jpg")
    end

    it "should be nil otherwise" do
      file = double('file')
      sanitized_file = CarrierWave::SanitizedFile.new(file)
      expect(sanitized_file.original_filename).to be_nil
    end
  end

  describe "#basename" do
    it "should return the basename for complicated extensions" do
      sanitized_file = CarrierWave::SanitizedFile.new(file_path("complex.filename.tar.gz"))

      expect(sanitized_file.basename).to eq("complex.filename")
    end

    it "should be the filename if the file has no extension" do
      sanitized_file = CarrierWave::SanitizedFile.new(file_path("complex"))

      expect(sanitized_file.basename).to eq("complex")
    end
  end

  describe "#extension" do
    %w[gz bz2 z lz xz].each do |ext|
      it "should return the extension for complicated extensions (tar.#{ext})" do
        sanitized_file = CarrierWave::SanitizedFile.new(file_path("complex.filename.tar.#{ext}"))

        expect(sanitized_file.extension).to eq("tar.#{ext}")
      end
    end

    it "should return the extension for real-world user file names" do
      sanitized_file = CarrierWave::SanitizedFile.new(file_path("Photo on 2009-12-01 at 11.12.jpg"))

      expect(sanitized_file.extension).to eq("jpg")
    end

    it "should return the extension for basic filenames" do
      sanitized_file = CarrierWave::SanitizedFile.new(file_path("something.png"))

      expect(sanitized_file.extension).to eq("png")
    end

    it "should be an empty string if the file has no extension" do
      sanitized_file = CarrierWave::SanitizedFile.new(file_path("complex"))

      expect(sanitized_file.extension).to eq("")
    end
  end

  describe "#filename" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(nil) }

    it "should default to the original filename if it is valid" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("llama.jpg")
      expect(sanitized_file.filename).to eq("llama.jpg")
    end

    it "should remove illegal characters from a filename" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("test-s,%&m#st?.jpg")
      expect(sanitized_file.filename).to eq("test-s___m_st_.jpg")
    end

    it "should remove slashes from the filename" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("../../very_tricky/foo.bar")
      expect(sanitized_file.filename).not_to match(/[\\\/]/)
    end

    it "should remove illegal characters if there is no extension" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("`*foo")
      expect(sanitized_file.filename).to eq("__foo")
    end

    it "should remove the path prefix on Windows" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return('c:\temp\foo.txt')
      expect(sanitized_file.filename).to eq("foo.txt")
    end

    it "should make sure the *nix directory thingies can't be used as filenames" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return(".")
      expect(sanitized_file.filename).to eq("_.")
    end

    it "should maintain uppercase filenames" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("DSC4056.JPG")
      expect(sanitized_file.filename).to eq("DSC4056.JPG")
    end

    it "should remove illegal characters from a non-ASCII filename" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("⟲«Du côté des chars lourds»_123.doc")
      expect(sanitized_file.filename).to eq("__Du_côté_des_chars_lourds__123.doc")
    end

    it "should default to the original non-ASCII filename if it is valid" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("тестовый.jpg")
      expect(sanitized_file.filename).to eq("тестовый.jpg")
    end

    it "should downcase non-ASCII characters properly" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("ТестоВый Ёжик.jpg")
      expect(sanitized_file.filename).to eq("ТестоВый_Ёжик.jpg")
    end
  end

  describe "#filename with an overridden sanitize_regexp" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(nil) }

    before do
      allow(sanitized_file).to receive(:sanitize_regexp).and_return(/[^a-zA-Z\.\-\+_]/)
    end

    it "should default to the original filename if it is valid" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("llama.jpg")
      expect(sanitized_file.filename).to eq("llama.jpg")
    end

    it "should remove illegal characters from a filename" do
      expect(sanitized_file).to receive(:original_filename).at_least(:once).and_return("123.jpg")
      expect(sanitized_file.filename).to eq("___.jpg")
    end
  end

  describe "#content_type" do
    it "preserves file's content_type" do
      sanitized_file = CarrierWave::SanitizedFile.new(content_type: "image/png")

      expect(sanitized_file.content_type).to eq("image/png")
    end

    it "preserves file's content_type when passed as type (Rack)" do
      sanitized_file = CarrierWave::SanitizedFile.new(type: "image/png")

      expect(sanitized_file.content_type).to eq("image/png")
    end

    it "handles Mime::Type object" do
      file = File.open(file_path('sponsored.doc'))
      allow(file).to receive(:content_type) { 'application/msword' }

      sanitized_file = CarrierWave::SanitizedFile.new(file)
      allow(sanitized_file).to receive(:file).and_return(file)

      expect { sanitized_file.content_type }.not_to raise_error
      expect(sanitized_file.content_type).to eq("application/msword")
    end

    it "reads content type from path if missing" do
      sanitized_file = CarrierWave::SanitizedFile.new("llama.jpg")

      expect(sanitized_file.content_type).to eq("image/jpeg")
    end

    it "does not allow spoofing of the mime type" do
      file = File.open(file_path("zip.png"))

      sanitized_file = CarrierWave::SanitizedFile.new(file)
      expect { sanitized_file.content_type }.not_to raise_error

      expect(sanitized_file.content_type).to eq("application/zip")
    end

    it "does not allow spoofing of the mime type if the mime type is not detectable" do
      file = File.open(file_path('spoof.png'))

      sanitized_file = CarrierWave::SanitizedFile.new(file)

      expect { sanitized_file.content_type }.not_to raise_error

      expect(sanitized_file.content_type).to_not eq 'image/png'
      expect(sanitized_file.content_type).to eq 'invalid/invalid'
    end

    it "does not raise an error if the path is not present" do
      sanitized_file = CarrierWave::SanitizedFile.new(nil)

      expect { sanitized_file.content_type }.not_to raise_error
    end
  end

  describe "#content_type=" do
    it "sets content_type" do
      sanitized_file = CarrierWave::SanitizedFile.new(content_type: "image/png")
      sanitized_file.content_type = "text/html"

      expect(sanitized_file.content_type).to eq("text/html")
    end
  end

  shared_examples_for "all valid sanitized files" do
    describe '#empty?' do
      it "should not be empty" do
        expect(sanitized_file).not_to be_empty
      end
    end

    describe '#original_filename' do
      it "should return the original filename" do
        expect(sanitized_file.original_filename).to eq("llama.jpg")
      end
    end

    describe "#filename" do
      it "should return the filename" do
        expect(sanitized_file.filename).to eq("llama.jpg")
      end
    end

    describe "#basename" do
      it "should return the basename" do
        expect(sanitized_file.basename).to eq("llama")
      end
    end

    describe "#extension" do
      it "should return the extension" do
        expect(sanitized_file.extension).to eq("jpg")
      end
    end

    describe "#read" do
      it "should return the contents of the file" do
        expect(sanitized_file.read).to eq("this is stuff")
      end
    end

    describe "#size" do
      it "should return the size of the file" do
        expect(sanitized_file.size).to eq(13)
      end
    end

    describe "#move_to" do
      after do
        FileUtils.rm_f(file_path("gurr.png"))
      end

      it "should be moved to the correct location" do
        sanitized_file.move_to(file_path("gurr.png"))

        expect(File.exist?( file_path("gurr.png") )).to be_truthy
      end

      it "should have changed its path when moved" do
        sanitized_file.move_to(file_path("gurr.png"))

        expect(sanitized_file.path).to eq(file_path("gurr.png"))
      end

      it "should have changed its filename when moved" do
        sanitized_file.move_to(file_path("gurr.png"))

        expect(sanitized_file.filename).to eq("gurr.png")
      end

      it "should have changed its basename when moved" do
        sanitized_file.move_to(file_path("gurr.png"))

        expect(sanitized_file.basename).to eq("gurr")
      end

      it "should have changed its extension when moved" do
        sanitized_file.move_to(file_path("gurr.png"))

        expect(sanitized_file.extension).to eq("png")
      end

      it "should set the right permissions" do
        sanitized_file.move_to(file_path("gurr.png"), 0755)

        expect(sanitized_file).to have_permissions(0755)
      end

      it "should set the right directory permissions" do
        sanitized_file.move_to(file_path("new_dir","gurr.png"), nil, 0775)

        expect(sanitized_file).to have_directory_permissions(0775)
      end

      it "should return itself" do
        expect(sanitized_file.move_to(file_path("gurr.png"))).to eq(sanitized_file)
      end

      it "should convert the file's content type" do
        sanitized_file.move_to(file_path("new_dir","gurr.png"))

        expect(sanitized_file.content_type).to eq("image/jpeg")
      end

      context 'target path only differs by case' do
        let(:upcased_sanitized_file) { CarrierWave::SanitizedFile.new(stub_file("upcase.JPG", "image/jpeg")) }

        before do
          FileUtils.cp(file_path("test.jpg"), file_path("upcase.JPG"))

          expect(upcased_sanitized_file).not_to be_empty
        end

	after(:all) do
	  FileUtils.rm_f(file_path("upcase.JPG"))
	  FileUtils.rm_f(file_path("upcase.jpg"))
        end

        it "should not raise an error when moved" do
          expect(running { upcased_sanitized_file.move_to(upcased_sanitized_file.path.downcase) }).not_to raise_error
        end
      end
    end

    describe "#copy_to" do
      after do
        FileUtils.rm_f(file_path("gurr.png"))
      end

      it "should be copied to the correct location" do
        sanitized_file.copy_to(file_path("gurr.png"))

        expect(File.exist?( file_path("gurr.png") )).to be_truthy

        expect(file_path("gurr.png")).to be_identical_to(file_path("llama.jpg"))
      end

      it "should not have changed its path when copied" do
        expect(running { sanitized_file.copy_to(file_path("gurr.png")) }).not_to change(sanitized_file, :path)
      end

      it "should not have changed its filename when copied" do
        expect(running { sanitized_file.copy_to(file_path("gurr.png")) }).not_to change(sanitized_file, :filename)
      end

      it "should return an object of the same class when copied" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"))

        expect(new_file).to be_an_instance_of(sanitized_file.class)
      end

      it "should adjust the path of the object that is returned when copied" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"))

        expect(new_file.path).to eq(file_path("gurr.png"))
      end

      it "should adjust the filename of the object that is returned when copied" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"))

        expect(new_file.filename).to eq("gurr.png")
      end

      it "should adjust the basename of the object that is returned when copied" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"))

        expect(new_file.basename).to eq("gurr")
      end

      it "should adjust the extension of the object that is returned when copied" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"))

        expect(new_file.extension).to eq("png")
      end

      it "should set the right permissions" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"), 0755)

        expect(new_file).to have_permissions(0755)
      end

      it "should set the right directory permissions" do
        new_file = sanitized_file.copy_to(file_path("new_dir", "gurr.png"), nil, 0755)

        expect(new_file).to have_directory_permissions(0755)
      end

      it "should preserve the file's content type" do
        new_file = sanitized_file.copy_to(file_path("gurr.png"))

        expect(new_file.content_type).to eq(sanitized_file.content_type)
      end
    end
  end

  shared_examples_for "all valid sanitized files that are stored on disk" do
    describe "#move_to" do
      it "should not raise an error when moved to its own location" do
        expect(running { sanitized_file.move_to(sanitized_file.path) }).not_to raise_error
      end

      it "should remove the original file" do
        original_path = sanitized_file.path
        sanitized_file.move_to(public_path("blah.txt"))

        expect(File.exist?(original_path)).to be_falsey
      end
    end

    describe '#copy_to' do
      it "should return a new instance when copied to its own location" do
        expect(running {
          new_file = sanitized_file.copy_to(sanitized_file.path)
          expect(new_file).to be_an_instance_of(sanitized_file.class)
        }).not_to raise_error
      end

      it "should not remove the original file" do
        new_file = sanitized_file.copy_to(public_path("blah.txt"))

        expect(File.exist?(sanitized_file.path)).to be_truthy
        expect(File.exist?(new_file.path)).to be_truthy
      end
    end

    describe "#exists?" do
      it "should be true" do
        expect(sanitized_file.exists?).to be_truthy
      end
    end

    describe "#delete" do
      it "should remove it from the filesystem" do
        expect(File.exist?(sanitized_file.path)).to be_truthy

        sanitized_file.delete

        expect(File.exist?(sanitized_file.path)).to be_falsey
      end
    end

    describe "#to_file" do
      it "should return a File object" do
        expect(sanitized_file.to_file).to be_a(File)
      end

      it "should have the same path as the SanitizedFile" do
        expect(sanitized_file.to_file.path).to eq(sanitized_file.path)
      end

      it "should have the same contents as the SantizedFile" do
        expect(sanitized_file.to_file.read).to eq(sanitized_file.read)
      end
    end
  end

  shared_examples_for "all valid sanitized files that are read from an IO object" do

    describe "#read" do
      it "should have an open IO object" do
        expect(sanitized_file.instance_variable_get(:@file).closed?).to be_falsey
      end

      it "should close the IO object after reading" do
        sanitized_file.read

        expect(sanitized_file.instance_variable_get(:@file).closed?).to be_truthy
      end
    end
  end

  describe "with a valid Hash" do
    let(:hash) {
      {
        "tempfile" => stub_merb_tempfile("llama.jpg"),
        "filename" => "llama.jpg",
        "content_type" => "image/jpeg"
      }
    }
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(hash) }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe "#path" do
      it "should return the path of the tempfile" do
        expect(sanitized_file.path).not_to be_nil
        expect(sanitized_file.path).to eq(hash["tempfile"].path)
      end
    end

    describe "#is_path?" do
      it "should be false" do
        expect(sanitized_file.is_path?).to be_falsey
      end
    end
  end

  describe "with a valid Tempfile" do
    let(:tempfile) { stub_tempfile("llama.jpg", "image/jpeg") }
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(tempfile) }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe "#is_path?" do
      it "should be false" do
        expect(sanitized_file.is_path?).to be_falsey
      end
    end

    describe "#path" do
      it "should return the path of the tempfile" do
        expect(sanitized_file.path).not_to be_nil
        expect(sanitized_file.path).to eq(tempfile.path)
      end
    end
  end

  describe "with a valid StringIO" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(stub_stringio("llama.jpg", "image/jpeg")) }

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe "#exists?" do
      it "should be false" do
        expect(sanitized_file.exists?).to be_falsey
      end
    end

    describe "#is_path?" do
      it "should be false" do
        expect(sanitized_file.is_path?).to be_falsey
      end
    end

    describe "#path" do
      it "should be nil" do
        expect(sanitized_file.path).to be_nil
      end
    end

    describe "#delete" do
      it "should not raise an error" do
        expect(running { sanitized_file.delete }).not_to raise_error
      end
    end

    describe "#to_file" do
      it "should be nil" do
        expect(sanitized_file.to_file).to be_nil
      end
    end
  end

  describe "with a valid File object" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(stub_file("llama.jpg", "image/jpeg")) }

    before do
      FileUtils.cp(file_path("test.jpg"), file_path("llama.jpg"))

      expect(sanitized_file).not_to be_empty
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe "#is_path?" do
      it "should be false" do
        expect(sanitized_file.is_path?).to be_falsey
      end
    end

    describe "#path" do
      it "should return the path of the file" do
        expect(sanitized_file.path).not_to be_nil
        expect(sanitized_file.path).to eq(file_path("llama.jpg"))
      end
    end
  end

  describe "with a valid File object and an empty file" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(stub_file("llama.jpg", "image/jpeg")) }

    before do
      FileUtils.cp(file_path("test.jpg"), file_path("llama.jpg"))
      FileUtils.rm file_path("llama.jpg")
      FileUtils.touch file_path("llama.jpg")

      expect(sanitized_file).not_to be_empty
    end

    it_should_behave_like "all valid sanitized files that are stored on disk"

    it_should_behave_like "all valid sanitized files that are read from an IO object"

    describe "#is_path?" do
      it "should be false" do
        expect(sanitized_file.is_path?).to be_falsey
      end
    end

    describe "#path" do
      it "should return the path of the file" do
        expect(sanitized_file.path).not_to be_nil
        expect(sanitized_file.path).to eq(file_path("llama.jpg"))
      end
    end
  end

  describe "with a valid path" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(file_path("llama.jpg")) }

    before do
      FileUtils.cp(file_path("test.jpg"), file_path("llama.jpg"))

      expect(sanitized_file).not_to be_empty
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe "#is_path?" do
      it "should be true" do
        expect(sanitized_file.is_path?).to be_truthy
      end
    end

    describe "#path" do
      it "should return the path of the file" do
        expect(sanitized_file.path).not_to be_nil
        expect(sanitized_file.path).to eq(file_path("llama.jpg"))
      end
    end

  end

  describe "with a valid Pathname" do
    let(:sanitized_file) { CarrierWave::SanitizedFile.new(Pathname.new(file_path("llama.jpg"))) }

    before do
      FileUtils.copy_file(file_path("test.jpg"), file_path("llama.jpg"))

      expect(sanitized_file).not_to be_empty
    end

    it_should_behave_like "all valid sanitized files"

    it_should_behave_like "all valid sanitized files that are stored on disk"

    describe "#is_path?" do
      it "should be true" do
        expect(sanitized_file.is_path?).to be_truthy
      end
    end

    describe "#path" do
      it "should return the path of the file" do
        expect(sanitized_file.path).not_to be_nil
        expect(sanitized_file.path).to eq(file_path("llama.jpg"))
      end
    end

  end

  describe "that is empty" do
    let(:empty) { CarrierWave::SanitizedFile.new(nil) }

    describe "#empty?" do
      it "should be true" do
        expect(empty).to be_empty
      end
    end

    describe "#exists?" do
      it "should be false" do
        expect(empty.exists?).to be_falsey
      end
    end

    describe "#is_path?" do
      it "should be false" do
        expect(empty.is_path?).to be_falsey
      end
    end

    describe "#size" do
      it "should be zero" do
        expect(empty.size).to be_zero
      end
    end

    describe "#path" do
      it "should be nil" do
        expect(empty.path).to be_nil
      end
    end

    describe "#original_filename" do
      it "should be nil" do
        expect(empty.original_filename).to be_nil
      end
    end

    describe "#filename" do
      it "should be nil" do
        expect(empty.filename).to be_nil
      end
    end

    describe "#basename" do
      it "should be nil" do
        expect(empty.basename).to be_nil
      end
    end

    describe "#extension" do
      it "should be nil" do
        expect(empty.extension).to be_nil
      end
    end

    describe "#delete" do
      it "should not raise an error" do
        expect(running { empty.delete }).not_to raise_error
      end
    end

    describe "#to_file" do
      it "should be nil" do
        expect(empty.to_file).to be_nil
      end
    end
  end

  describe "that is an empty string" do
    let(:empty) { CarrierWave::SanitizedFile.new("") }

    describe "#empty?" do
      it "should be true" do
        expect(empty).to be_empty
      end
    end

    describe "#exists?" do
      it "should be false" do
        expect(empty.exists?).to be_falsey
      end
    end

    describe "#is_path?" do
      it "should be false" do
        expect(empty.is_path?).to be_falsey
      end
    end

    describe "#size" do
      it "should be zero" do
        expect(empty.size).to be_zero
      end
    end

    describe "#path" do
      it "should be nil" do
        expect(empty.path).to be_nil
      end
    end

    describe "#original_filename" do
      it "should be nil" do
        expect(empty.original_filename).to be_nil
      end
    end

    describe "#filename" do
      it "should be nil" do
        expect(empty.filename).to be_nil
      end
    end

    describe "#basename" do
      it "should be nil" do
        expect(empty.basename).to be_nil
      end
    end

    describe "#extension" do
      it "should be nil" do
        expect(empty.extension).to be_nil
      end
    end

    describe "#delete" do
      it "should not raise an error" do
        expect(running { empty.delete }).not_to raise_error
      end
    end

    describe "#to_file" do
      it "should be nil" do
        expect(empty.to_file).to be_nil
      end
    end
  end
end
