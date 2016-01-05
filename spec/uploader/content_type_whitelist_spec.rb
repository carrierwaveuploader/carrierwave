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
        allow(@uploader).to receive(:content_type_whitelist).and_return(nil)

        expect {
          @uploader.cache!(File.open(file_path('ruby.gif')))
        }.not_to raise_error
      end
    end

    context "when there is a whitelist" do
      context "when the whitelist is an array of values" do
        it "does not raise an integrity error when the file has a whitelisted content type" do
          allow(@uploader).to receive(:content_type_whitelist).and_return(['image/gif'])

          expect {
            @uploader.cache!(File.open(file_path('ruby.gif')))
          }.not_to raise_error
        end

        it "raises an integrity error the file has not a whitelisted content type" do
          allow(@uploader).to receive(:content_type_whitelist).and_return(['image/gif'])

          expect {
            @uploader.cache!(File.open(file_path('bork.txt')))
          }.to raise_error(CarrierWave::IntegrityError)
        end

        it "accepts content types as regular expressions" do
          allow(@uploader).to receive(:content_type_whitelist).and_return([/image\//])

          expect {
            @uploader.cache!(File.open(file_path('bork.txt')))
          }.to raise_error(CarrierWave::IntegrityError)
        end
      end

      context "when the whitelist is a single value" do
        it "accepts a single extension string value" do
          allow(@uploader).to receive(:extension_whitelist).and_return('jpeg')

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpeg')))
          }).not_to raise_error
        end

        it "accepts a single extension regular expression value" do
          allow(@uploader).to receive(:extension_whitelist).and_return(/jpe?g/)

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpeg')))
          }).not_to raise_error
        end
      end
    end
  end
end
