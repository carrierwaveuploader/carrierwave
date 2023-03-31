require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }

  after { FileUtils.rm_rf(public_path) }

  describe '.process' do
    context "when a symbol is given" do
      before { uploader_class.process(process_param) }
      after { uploader.process! }

      let(:process_param) { :sepiatone }

      it "adds a single processor" do
        expect(uploader).to receive(:sepiatone)
      end
    end

    context "when an array of symbols is given" do
      before { uploader_class.process(*process_param) }
      after { uploader.process! }

      let(:process_param) { [:sepiatone, :desaturate, :invert] }

      it "adds multiple processors" do
        expect(uploader).to receive(:sepiatone)
        expect(uploader).to receive(:desaturate)
        expect(uploader).to receive(:invert)
      end
    end

    it "adds a single processor with an argument when a hash is given" do
      uploader_class.process :format => 'png'
      expect(uploader).to receive(:format).with('png')
      uploader.process!
    end

    it "adds a single processor with several argument when a hash is given" do
      uploader_class.process :resize => [200, 300]
      expect(uploader).to receive(:resize).with(200, 300)
      uploader.process!
    end

    it "adds multiple processors when an hash with multiple keys is given" do
      uploader_class.process :resize => [200, 300], :format => 'png'
      expect(uploader).to receive(:resize).with(200, 300)
      expect(uploader).to receive(:format).with('png')
      uploader.process!
    end

    context "when there is an 'if' condition" do
      it "calls the processor if the condition method returns true" do
        uploader_class.process :resize => [200, 300], :if => :true?
        uploader_class.process :fancy, :if => :true?
        expect(uploader).to receive(:true?).with("test.jpg").twice.and_return(true)
        expect(uploader).to receive(:resize).with(200, 300)
        expect(uploader).to receive(:fancy)
        uploader.process!("test.jpg")
      end

      it "doesn't call the processor if the condition method returns false" do
        uploader_class.process :resize => [200, 300], :if => :false?
        uploader_class.process :fancy, :if => :false?
        expect(uploader).to receive(:false?).with("test.jpg").twice.and_return(false)
        expect(uploader).not_to receive(:resize)
        expect(uploader).not_to receive(:fancy)
        uploader.process!("test.jpg")
      end

      it "calls the processor if the condition block returns true" do
        uploader_class.process :resize => [200, 300], :if => lambda{|record, args| record.true?(args[:file])}
        uploader_class.process :fancy, :if => :true?
        expect(uploader).to receive(:true?).with("test.jpg").twice.and_return(true)
        expect(uploader).to receive(:resize).with(200, 300)
        expect(uploader).to receive(:fancy)
        uploader.process!("test.jpg")
      end

      it "doesn't call the processor if the condition block returns false" do
        uploader_class.process :resize => [200, 300], :if => lambda{|record, args| record.false?(args[:file])}
        uploader_class.process :fancy, :if => :false?
        expect(uploader).to receive(:false?).with("test.jpg").twice.and_return(false)
        expect(uploader).not_to receive(:resize)
        expect(uploader).not_to receive(:fancy)
        uploader.process!("test.jpg")
      end
    end

    context "when there is an 'unless' condition" do
      it "doesn't call the processor if the condition method returns true" do
        uploader_class.process :resize => [200, 300], :unless => :true?
        uploader_class.process :fancy, :unless => :true?
        expect(uploader).to receive(:true?).with("test.jpg").twice.and_return(true)
        expect(uploader).not_to receive(:resize).with(200, 300)
        expect(uploader).not_to receive(:fancy)
        uploader.process!("test.jpg")
      end

      it "calls the processor if the condition method returns false" do
        uploader_class.process :resize => [200, 300], :unless => :false?
        uploader_class.process :fancy, :unless => :false?
        expect(uploader).to receive(:false?).with("test.jpg").twice.and_return(false)
        expect(uploader).to receive(:resize)
        expect(uploader).to receive(:fancy)
        uploader.process!("test.jpg")
      end

      it "doesn't call the processor if the condition block returns true" do
        uploader_class.process :resize => [200, 300], :unless => lambda{|record, args| record.true?(args[:file])}
        uploader_class.process :fancy, :unless => :true?
        expect(uploader).to receive(:true?).with("test.jpg").twice.and_return(true)
        expect(uploader).not_to receive(:resize).with(200, 300)
        expect(uploader).not_to receive(:fancy)
        uploader.process!("test.jpg")
      end

      it "calls the processor if the condition block returns false" do
        uploader_class.process :resize => [200, 300], :unless => lambda{|record, args| record.false?(args[:file])}
        uploader_class.process :fancy, :unless => :false?
        expect(uploader).to receive(:false?).with("test.jpg").twice.and_return(false)
        expect(uploader).to receive(:resize)
        expect(uploader).to receive(:fancy)
        uploader.process!("test.jpg")
      end
    end

    context "when there are additional method key word arguments" do
      it "calls the processor if the condition method returns true" do
        uploader_class.process :resize => [200, 300, {combine_options: { quality: 70 }}], :if => :true?
        expect(uploader).to receive(:true?).with("test.jpg").once.and_return(true)
        expect(uploader).to receive(:resize).with(200, 300, combine_options: { quality: 70 })
        uploader.process!("test.jpg")
      end
    end

    context "with 'enable_processing' set to false" do
      before { uploader_class.enable_processing = false }

      it "doesn't do any processing" do
        uploader_class.process :sepiatone, :desaturate, :invert
        expect(uploader).not_to receive(:sepiatone)
        expect(uploader).not_to receive(:desaturate)
        expect(uploader).not_to receive(:invert)
        uploader.process!
      end
    end
  end

  describe '#cache!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "triggers a process!" do
      expect(uploader).to receive(:process!)
      uploader.cache!(File.open(file_path('test.jpg')))
    end
  end

  describe '#forcing_extension' do
    it "works with a symbol" do
      uploader.force_extension = :png
      expect(uploader.send(:forcing_extension, 'test.jpg')).to eq 'test.png'
    end

    it "works with a string without dot" do
      uploader.force_extension = 'png'
      expect(uploader.send(:forcing_extension, 'test.jpg')).to eq 'test.png'
    end

    it "works with a string with dot" do
      uploader.force_extension = '.png'
      expect(uploader.send(:forcing_extension, 'test.jpg')).to eq 'test.png'
    end

    it "does nothing when force_extension is false" do
      uploader.force_extension = false
      expect(uploader.send(:forcing_extension, 'test.jpg')).to eq 'test.jpg'
    end
  end

  context "when using #convert" do
    let(:another_uploader) { uploader_class.new }
    before do
      uploader_class.class_eval do
        include CarrierWave::MiniMagick
        process convert: :png
      end
    end

    it "performs the processing" do
      uploader.cache!(File.open(file_path('landscape.jpg')))
      expect(uploader).to be_format('png')
      expect(uploader.file.filename).to eq 'landscape.png'
    end

    it "does not change #original_filename but changes #cache_path and #url to have new extension" do
      uploader.cache!(File.open(file_path('landscape.jpg')))
      expect(uploader.send(:original_filename)).to eq 'landscape.jpg'
      expect(uploader.cache_name.split('/').last).to eq 'landscape.jpg'
      expect(File.basename(uploader.cache_path)).to eq 'landscape.png'
      expect(File.basename(uploader.url)).to eq 'landscape.png'
    end

    it "changes #filename to have new extension" do
      uploader.store!(File.open(file_path('landscape.jpg')))
      expect(uploader.identifier).to eq 'landscape.jpg'
      expect(File.basename(uploader.store_path)).to eq 'landscape.png'
      expect(File.basename(uploader.url)).to eq 'landscape.png'
    end

    it "allows the cached file to be retrieved" do
      uploader.cache!(File.open(file_path('landscape.jpg')))
      another_uploader.retrieve_from_cache!(uploader.cache_name)
      expect(another_uploader.cache_path).to eq uploader.cache_path
      expect(another_uploader.url).to eq uploader.url
    end

    it "allows the stored file to be retrieved" do
      uploader.store!(File.open(file_path('landscape.jpg')))
      another_uploader.retrieve_from_store!(uploader.identifier)
      expect(another_uploader.identifier).to eq uploader.identifier
      expect(another_uploader.url).to eq uploader.url
    end

    context "with #filename overridden" do
      let(:changed_extension) { '.png' }

      before do
        uploader_class.class_eval <<-RUBY, __FILE__, __LINE__+1
          def filename
            super.chomp(File.extname(super)) + '#{changed_extension}'
          end
        RUBY
      end

      it "stores the file" do
        uploader.store!(File.open(file_path('landscape.jpg')))
        expect(uploader.filename).to eq 'landscape.png'
      end

      it "retrieves the file" do
        uploader.store!(File.open(file_path('landscape.jpg')))
        another_uploader.retrieve_from_store!(uploader.identifier)
        expect(another_uploader.identifier).to eq uploader.identifier
        expect(another_uploader.url).to eq uploader.url
      end

      context "to have a wrong extension" do
        let(:changed_extension) { '.gif' }

        it "uses the wrong one" do
          uploader.store!(File.open(file_path('landscape.jpg')))
          expect(uploader.filename).to eq 'landscape.gif'
          expect(uploader).to be_format('png')
        end
      end
    end
  end

  context "when file extension changes not using #convert" do
    let(:another_uploader) { uploader_class.new }
    before do
      uploader_class.class_eval do
        def rename
          file.move_to 'landscape.bin'
        end
        process :rename
      end
    end

    it "performs the processing without changing #idenfitier" do
      uploader.cache!(File.open(file_path('landscape.jpg')))
      expect(uploader.file.filename).to eq 'landscape.bin'
      expect(uploader.identifier).to eq 'landscape.jpg'
    end

    context "but applying #force_extension" do
      before do
        uploader_class.class_eval do
          force_extension '.bin'
        end
      end

      it "changes #filename to have the extension" do
        uploader.store!(File.open(file_path('landscape.jpg')))
        expect(uploader.identifier).to eq 'landscape.jpg'
        expect(File.basename(uploader.store_path)).to eq 'landscape.bin'
      end
    end

    context "but overriding #filename" do
      before do
        uploader_class.class_eval <<-RUBY, __FILE__, __LINE__+1
          def filename
            super.chomp(File.extname(super)) + '.bin'
          end
        RUBY
      end

      it "changes #filename to have the extension" do
        uploader.store!(File.open(file_path('landscape.jpg')))
        expect(uploader.identifier).to eq 'landscape.bin'
        expect(File.basename(uploader.store_path)).to eq 'landscape.bin'
      end

      it "retrieves the file by using the overridden name" do
        uploader.store!(File.open(file_path('landscape.jpg')))
        another_uploader.retrieve_from_store!(uploader.identifier)
        expect(another_uploader.identifier).to eq uploader.identifier
        expect(another_uploader.url).to eq uploader.url
      end
    end
  end
end
