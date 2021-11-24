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

    context "when using RMagick", :rmagick => true do
      before do
        def uploader.cover
          manipulate! { |frame, index| frame if index.zero? }
        end

        uploader_class.send :include, CarrierWave::RMagick
      end

      after { uploader.instance_eval { undef cover } }

      context "with a multi-page PDF" do
        before { uploader.cache! File.open(file_path("multi_page.pdf")) }

        it "successfully processes" do
          uploader_class.process :convert => 'jpg'
          uploader.process!
        end

        it "supports page specific transformations" do
          uploader_class.process :cover
          uploader.process!
        end
      end

      context "with a simple image" do
        before { uploader.cache! File.open(file_path("portrait.jpg")) }

        it "allows page specific transformations" do
          uploader_class.process :cover
          uploader.process!
        end
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

  describe '#recreate_versions!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    it "triggers a process!" do
      uploader.store!(File.open(file_path('test.jpg')))
      expect(uploader).to receive(:process!)
      uploader.recreate_versions!
    end
  end
end
