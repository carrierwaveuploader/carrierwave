require 'spec_helper'

describe CarrierWave::Uploader do
  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#cache!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    context "when there is no whitelist" do
      it "does not raise an integrity error" do
        allow(@uploader).to receive(:extension_whitelist).and_return(nil)

        expect(running {
          @uploader.cache!(File.open(file_path('test.jpg')))
        }).not_to raise_error
      end
    end

    context "when there is a whitelist" do
      context "when the whitelist is an array of values" do
        it "does not raise an integrity error when the file has a whitelisted extension" do
          allow(@uploader).to receive(:extension_whitelist).and_return(%w(jpg gif png))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).not_to raise_error
        end

        it "raises an integrity error if the file has not a whitelisted extension" do
          allow(@uploader).to receive(:extension_whitelist).and_return(%w(txt doc xls))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).to raise_error(CarrierWave::IntegrityError)
        end

        it "raises an integrity error if the file has not a whitelisted extension, using start of string matcher" do
          allow(@uploader).to receive(:extension_whitelist).and_return(%w(txt))

          expect(running {
            @uploader.cache!(File.open(file_path('bork.ttxt')))
          }).to raise_error(CarrierWave::IntegrityError)
        end

        it "raises an integrity error if the file has not a whitelisted extension, using end of string matcher" do
          allow(@uploader).to receive(:extension_whitelist).and_return(%w(txt))

          expect(running {
            @uploader.cache!(File.open(file_path('bork.txtt')))
          }).to raise_error(CarrierWave::IntegrityError)
        end

        it "compares extensions in a case insensitive manner when capitalized extension provided" do
          allow(@uploader).to receive(:extension_whitelist).and_return(%w(jpg gif png))

          expect(running {
            @uploader.cache!(File.open(file_path('case.JPG')))
          }).not_to raise_error
        end

        it "compares extensions in a case insensitive manner when lowercase extension provided" do
          allow(@uploader).to receive(:extension_whitelist).and_return(%w(JPG GIF PNG))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).not_to raise_error
        end

        it "accepts extensions as regular expressions" do
          allow(@uploader).to receive(:extension_whitelist).and_return([/jpe?g/, 'gif', 'png'])

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpeg')))
          }).not_to raise_error
        end

        it "accepts extensions as regular expressions in a case insensitive manner" do

          allow(@uploader).to receive(:extension_whitelist).and_return([/jpe?g/, 'gif', 'png'])
          expect(running {
            @uploader.cache!(File.open(file_path('case.JPG')))
          }).not_to raise_error
        end
      end

      context "when the whitelist is a single value" do
        it "accepts a single extension string value" do
          allow(@uploader).to receive(:extension_whitelist).and_return('jpeg')

          expect { @uploader.cache!(File.open(file_path('test.jpg'))) }.to raise_error(CarrierWave::IntegrityError)
        end

        it "accepts a single extension regular expression value" do
          allow(@uploader).to receive(:extension_whitelist).and_return(/jpe?g/)

          expect { @uploader.cache!(File.open(file_path('bork.txt')))}.to raise_error(CarrierWave::IntegrityError)

        end
      end
    end
  end
end
