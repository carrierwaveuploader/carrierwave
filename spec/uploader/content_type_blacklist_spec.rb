require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:landscape_file) { File.open(file_path('landscape.jpg')) }
  let(:bork_file) { File.open(file_path('bork.txt')) }
  let(:test_file) { File.open(file_path('test.jpeg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    before do
      CarrierWave.stub(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    context "when there is no blacklist" do
      it "does not raise an integrity error" do
        uploader.stub(:content_type_blacklist).and_return(nil)

        lambda { uploader.cache!(landscape_file) }.should_not raise_error
      end
    end

    context "when there is a blacklist" do
      context "when the blacklist is an array of values" do
        it "does not raise an integrity error when the file has not a blacklisted content type" do
          uploader.stub(:content_type_blacklist).and_return(['image/gif'])

          lambda { uploader.cache!(bork_file) }.should_not raise_error
        end

        it "raises an integrity error if the file has a blacklisted content type" do
          uploader.stub(:content_type_blacklist).and_return(['image/jpeg'])

          lambda { uploader.cache!(landscape_file) }.should raise_error(CarrierWave::IntegrityError)
        end

        it "accepts content types as regular expressions" do
          uploader.stub(:content_type_blacklist).and_return([/image\//])

          lambda { uploader.cache!(landscape_file) }.should raise_error(CarrierWave::IntegrityError)
        end
      end
    end
  end
end
