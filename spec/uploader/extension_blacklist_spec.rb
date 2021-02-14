require 'spec_helper'

describe CarrierWave::Uploader do
  subject { lambda { uploader.cache!(test_file) } }

  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '1369894322-345-1234-2255' }
  let(:test_file_name) { 'test.jpg' }
  let(:test_file) { File.open(file_path(test_file_name)) }

  after { FileUtils.rm_rf(public_path) }

  before { allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id) }

  describe '#cache!' do
    before { allow(uploader).to receive(:extension_blocklist).and_return(extension_blacklist) }

    context "when there are no blacklisted extensions" do
      let(:extension_blacklist) { nil }

      it "doesn't raise an integrity error" do
        is_expected.not_to raise_error
      end
    end

    context "when there is a blacklist" do
      context "when the blacklist is an array of values" do
        context "when the file extension matches a blacklisted extension" do
          let(:extension_blacklist) { %w(jpg gif png) }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file extension doesn't match a blacklisted extension" do
          let(:extension_blacklist) { %w(txt doc xls) }

          it "doesn't raise an integrity error" do
            is_expected.to_not raise_error
          end
        end

        context "when the file extension has only the starting part of a blacklisted extension string" do
          let(:text_file_name) { 'bork.ttxt' }
          let(:extension_blacklist) { %w(txt) }

          it "doesn't raise an integrity error" do
            is_expected.to_not raise_error
          end
        end

        context "when the file extension has only the ending part of a blacklisted extension string" do
          let(:text_file_name) { 'bork.txtt' }
          let(:extension_blacklist) { %w(txt) }

          it "doesn't raise an integrity error" do
            is_expected.to_not raise_error
          end
        end

        context "when the file has a capitalized extension of a blacklisted extension" do
          let(:text_file_name) { 'case.JPG' }
          let(:extension_blacklist) { %w(jpg gif png) }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file has an extension which matches a blacklisted capitalized extension" do
          let(:text_file_name) { 'test.jpg' }
          let(:extension_blacklist) { %w(JPG GIF PNG) }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file has an extension which matches the blacklisted extension regular expression" do
          let(:text_file_name) { 'test.jpeg' }
          let(:extension_blacklist) { [/jpe?g/, 'gif', 'png'] }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end
      end

      context "when the blacklist is a single value" do
        context "when the file has an extension which is equal the blacklisted extension string" do
          let(:test_file_name) { 'test.jpeg' }
          let(:extension_blacklist) { 'jpeg' }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file has a name which matches the blacklisted extension regular expression" do
          let(:text_file_name) { 'test.jpeg' }
          let(:extension_blacklist) { /jpe?g/ }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end
      end
    end
  end
end
