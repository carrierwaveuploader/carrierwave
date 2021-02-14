require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:ruby_file) { File.open(file_path('ruby.gif')) }
  let(:bork_file) { File.open(file_path('bork.txt')) }
  let(:test_file) { File.open(file_path('test.jpeg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    context "when there is no blacklist" do
      it "does not raise an integrity error" do
        allow(uploader).to receive(:content_type_blacklist).and_return(nil)

        expect { uploader.cache!(ruby_file) }.not_to raise_error
      end
    end

    context "when there is a blacklist" do
      context "when the blacklist is an array of values" do
        it "does not raise an integrity error when the file has not a blacklisted content type" do
          allow(uploader).to receive(:content_type_blacklist).and_return(['image/gif'])

          expect { uploader.cache!(bork_file) }.not_to raise_error
        end

        it "raises an integrity error if the file has a blacklisted content type" do
          allow(uploader).to receive(:content_type_blacklist).and_return(['image/png'])

          expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError)
        end

        it "raises an integrity error if the file has a blocklisted content type" do
          allow(uploader).to receive(:content_type_blocklist).and_return(['image/png'])

          expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError)
        end

        it "accepts content types as regular expressions" do
          allow(uploader).to receive(:content_type_blacklist).and_return([/image\//])

          expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError)
        end
      end

      context "when the blacklist is a single value" do
        it "accepts a single extension string value" do
          allow(uploader).to receive(:extension_whitelist).and_return('jpeg')

          expect { uploader.cache!(test_file) }.not_to raise_error
        end

        it "accepts a single extension regular expression value" do
          allow(uploader).to receive(:extension_whitelist).and_return(/jpe?g/)

          expect { uploader.cache!(test_file) }.not_to raise_error
        end
      end
    end
  end
end
