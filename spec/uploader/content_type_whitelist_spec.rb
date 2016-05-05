require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:image_file) { File.open(file_path('landscape.jpg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    before do
      CarrierWave.stub(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    context "when there is no whitelist" do
      it "does not raise an integrity error" do
        uploader.stub(:content_type_whitelist).and_return(nil)

        lambda { uploader.cache!(image_file) }.should_not raise_error
      end
    end

    context "when there is a whitelist" do
      context "when the whitelist is an array of values" do
        let(:bork_file) { File.open(file_path('bork.txt')) }

        it "does not raise an integrity error when the file has a whitelisted content type" do
          uploader.stub(:content_type_whitelist).and_return(['image/jpeg'])

          lambda { uploader.cache!(image_file) }.should_not raise_error
        end

        it "raises an integrity error the file has not a whitelisted content type" do
          uploader.stub(:content_type_whitelist).and_return(['image/jpeg'])

          lambda { uploader.cache!(bork_file) }.should raise_error(CarrierWave::IntegrityError)
        end

        it "accepts content types as regular expressions" do
          uploader.stub(:content_type_whitelist).and_return([/image\//])

          lambda { uploader.cache!(bork_file) }.should raise_error(CarrierWave::IntegrityError)
        end
      end
    end
  end
end
