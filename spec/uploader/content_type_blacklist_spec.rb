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

    context "when there is no denylist" do
      it "does not raise an integrity error" do
        allow(uploader).to receive(:content_type_denylist).and_return(nil)

        expect { uploader.cache!(ruby_file) }.not_to raise_error
      end
    end

    context "when there is a denylist" do
      context "when the denylist is an array of values" do
        it "does not raise an integrity error when the file has not a denylisted content type" do
          allow(uploader).to receive(:content_type_denylist).and_return(['image/gif'])

          expect { uploader.cache!(bork_file) }.not_to raise_error
        end

        it "raises an integrity error if the file has a denylisted content type" do
          allow(uploader).to receive(:content_type_denylist).and_return(['image/png'])

          expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError, 'You are not allowed to upload image/png files')
        end

        it "accepts content types as regular expressions" do
          allow(uploader).to receive(:content_type_denylist).and_return([/image\//])

          expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError)
        end
      end

      context "when the denylist is a single value" do
        it "accepts a single content type string value" do
          allow(uploader).to receive(:content_type_denylist).and_return('image/gif')

          expect { uploader.cache!(ruby_file) }.not_to raise_error
        end

        it "accepts a single content type regular expression value" do
          allow(uploader).to receive(:content_type_denylist).and_return(/image\/gif/)

          expect { uploader.cache!(ruby_file) }.not_to raise_error
        end
      end
    end

    context "when there is a blacklist" do
      it "uses the blacklist but shows deprecation" do
        allow(uploader).to receive(:content_type_blacklist).and_return(['image/png'])

        expect(ActiveSupport::Deprecation).to receive(:warn).with('#content_type_blacklist is deprecated, use #content_type_denylist instead.')
        expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError)
      end

      it "looks for content_type_whitelist first for I18n translation" do
        allow(uploader).to receive(:content_type_denylist).and_return(['image/png'])

        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :content_type_denylist_error => "this will not be used",
            :content_type_blacklist_error => "Het is niet toegestaan om %{content_type} bestanden te uploaden"
          }
        }) do
          expect { uploader.cache!(ruby_file) }.to raise_error(CarrierWave::IntegrityError, 'Het is niet toegestaan om image/png bestanden te uploaden')
        end
      end
    end
  end
end
