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

    context "when there is no allowlist" do
      it "does not raise an integrity error" do
        allow(@uploader).to receive(:extension_allowlist).and_return(nil)

        expect(running {
          @uploader.cache!(File.open(file_path('test.jpg')))
        }).not_to raise_error
      end
    end

    context "when there is an allowlist" do
      context "when the allowlist is an array of values" do
        it "does not raise an integrity error when the file has an allowlisted extension" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(jpg gif png))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).not_to raise_error
        end

        it "raises an integrity error if the file has not an allowlisted extension" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(txt doc xls))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).to raise_error(CarrierWave::IntegrityError, 'You are not allowed to upload "jpg" files, allowed types: txt, doc, xls')
        end

        it "raises an integrity error if the file has not an allowlisted extension" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(txt doc xls))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).to raise_error(CarrierWave::IntegrityError)
        end

        it "raises an integrity error if the file has not an allowlisted extension, using start of string matcher" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(txt))

          expect(running {
            @uploader.cache!(File.open(file_path('bork.ttxt')))
          }).to raise_error(CarrierWave::IntegrityError)
        end

        it "raises an integrity error if the file has not an allowlisted extension, using end of string matcher" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(txt))

          expect(running {
            @uploader.cache!(File.open(file_path('bork.txtt')))
          }).to raise_error(CarrierWave::IntegrityError)
        end

        it "compares extensions in a case insensitive manner when capitalized extension provided" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(jpg gif png))

          expect(running {
            @uploader.cache!(File.open(file_path('case.JPG')))
          }).not_to raise_error
        end

        it "compares extensions in a case insensitive manner when lowercase extension provided" do
          allow(@uploader).to receive(:extension_allowlist).and_return(%w(JPG GIF PNG))

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).not_to raise_error
        end

        it "accepts extensions as regular expressions" do
          allow(@uploader).to receive(:extension_allowlist).and_return([/jpe?g/, 'gif', 'png'])

          expect(running {
            @uploader.cache!(File.open(file_path('test.jpeg')))
          }).not_to raise_error
        end

        it "accepts extensions as regular expressions in a case insensitive manner" do

          allow(@uploader).to receive(:extension_allowlist).and_return([/jpe?g/, 'gif', 'png'])
          expect(running {
            @uploader.cache!(File.open(file_path('case.JPG')))
          }).not_to raise_error
        end
      end

      context "when the allowlist is a single value" do
        it "accepts a single extension string value" do
          allow(@uploader).to receive(:extension_allowlist).and_return('jpeg')

          expect { @uploader.cache!(File.open(file_path('test.jpg'))) }.to raise_error(CarrierWave::IntegrityError)
        end

        it "accepts a single extension regular expression value" do
          allow(@uploader).to receive(:extension_allowlist).and_return(/jpe?g/)

          expect { @uploader.cache!(File.open(file_path('bork.txt')))}.to raise_error(CarrierWave::IntegrityError)

        end
      end
    end

    context "when there is a whitelist" do
      it "uses the whitelist but shows deprecation" do
        allow(@uploader).to receive(:extension_whitelist).and_return(%w(txt doc xls))

        expect(ActiveSupport::Deprecation).to receive(:warn).with('#extension_whitelist is deprecated, use #extension_allowlist instead.')
        expect(running {
          @uploader.cache!(File.open(file_path('test.jpg')))
        }).to raise_error(CarrierWave::IntegrityError)
      end

      it "looks for extension_whitelist first for I18n translation" do
        allow(@uploader).to receive(:extension_allowlist).and_return(%w(txt doc xls))

        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :extension_allowlist_error => "this will not be used",
            :extension_whitelist_error => "Het is niet toegestaan om %{extension} bestanden te uploaden; toegestane bestandstypes: %{allowed_types}"
          }
        }) do
          expect(running {
            @uploader.cache!(File.open(file_path('test.jpg')))
          }).to raise_error(CarrierWave::IntegrityError, 'Het is niet toegestaan om "jpg" bestanden te uploaden; toegestane bestandstypes: txt, doc, xls')
        end
      end
    end
  end
end
