require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:ruby_file) { File.open(file_path('ruby.gif')) }
  let(:bork_file) { File.open(file_path('bork.txt')) }
  let(:vector_file) { File.open(file_path('ruby.svg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#cache!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
    end

    context "when there is no allowlist" do
      it "does not raise an integrity error" do
        allow(uploader).to receive(:content_type_allowlist).and_return(nil)

        expect { uploader.cache!(ruby_file) }.not_to raise_error
      end
    end

    context "when there is an allowlist" do
      context "when the allowlist is an array of values" do
        it "does not raise an integrity error when the file has an allowlisted content type" do
          allow(uploader).to receive(:content_type_allowlist).and_return(['image/png'])

          expect { uploader.cache!(ruby_file) }.not_to raise_error
        end

        it "accepts content types with a + symbol" do
          allow(uploader).to receive(:content_type_allowlist).and_return(['image/svg+xml'])

          expect { uploader.cache!(vector_file) }.not_to raise_error
        end

        it "accepts a list of content types with mixed regular expressions and strings" do
          allow(uploader).to receive(:content_type_allowlist).and_return(['application/pdf', %r{image/}])

          expect { uploader.cache!(ruby_file) }.not_to raise_error
        end

        it "raises an integrity error the file has not an allowlisted content type" do
          allow(uploader).to receive(:content_type_allowlist).and_return(['image/gif'])

          expect { uploader.cache!(bork_file) }.to raise_error(CarrierWave::IntegrityError)
        end

        it "accepts content types as regular expressions" do
          allow(uploader).to receive(:content_type_allowlist).and_return([/image\//])

          expect { uploader.cache!(bork_file) }.to raise_error(CarrierWave::IntegrityError)
        end

        it "raises an integrity error which lists the allowed content types" do
          allow(uploader).to receive(:content_type_allowlist).and_return(['image/gif', 'image/jpg'])

          expect { uploader.cache!(bork_file) }.to raise_error(CarrierWave::IntegrityError, %r{(?:image/gif|image/jpg)})
        end
      end

      context "when the allowlist is a single value" do
        let(:test_file) { File.open(file_path('test.jpeg')) }

        it "accepts a single content type string value" do
          allow(uploader).to receive(:content_type_allowlist).and_return('image/png')

          expect { uploader.cache!(ruby_file) }.not_to raise_error
        end

        it "accepts a single content type regular expression value" do
          allow(uploader).to receive(:content_type_allowlist).and_return(/image\//)

          expect { uploader.cache!(ruby_file) }.not_to raise_error
        end
      end
    end

    context "when there is a whitelist" do
      it "uses the whitelist but shows deprecation" do
        allow(uploader).to receive(:content_type_whitelist).and_return(['image/gif'])

        expect(ActiveSupport::Deprecation).to receive(:warn).with('#content_type_whitelist is deprecated, use #content_type_allowlist instead.')
        expect(running {
          uploader.cache!(bork_file)
        }).to raise_error(CarrierWave::IntegrityError)
      end

      it "looks for content_type_allowlist first for I18n translation" do
        allow(uploader).to receive(:content_type_allowlist).and_return(['image/gif'])

        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :content_type_whitelist_error => "this will not be used",
            :content_type_allowlist_error => "Het is niet toegestaan om %{content_type} bestanden te uploaden"
          }
        }) do
          expect(running {
            uploader.cache!(bork_file)
          }).to raise_error(CarrierWave::IntegrityError, 'Het is niet toegestaan om text/plain bestanden te uploaden')
        end
      end
    end
  end
end
