require 'spec_helper'

describe CarrierWave::Uploader do
  subject { lambda { uploader.cache!(test_file) } }

  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '1369894322-345-1234-2255' }
  let(:test_file_name) { 'test.jpg' }
  let(:test_file) { File.open(file_path(test_file_name)) }

  after { FileUtils.rm_rf(public_path) }
  before do
    allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id)
    uploader.instance_variable_set(:@extension_denylist_warned, true)
  end

  describe '#cache!' do
    context "when there are no denylisted extensions" do
      it "doesn't raise an integrity error" do
        is_expected.not_to raise_error
      end
    end

    context "when there is a denylist" do
      before { allow(uploader).to receive(:extension_denylist).and_return(extension_denylist) }

      describe "deprecation" do
        let(:extension_denylist) { %w(jpg) }
        before do
          uploader.remove_instance_variable(:@extension_denylist_warned)
        end

        it "shows up" do
          expect(ActiveSupport::Deprecation).to receive(:warn).with('Use of #extension_denylist is deprecated for the security reason, use #extension_allowlist instead to explicitly state what are safe to accept')
          is_expected.to raise_error(CarrierWave::IntegrityError)
        end
      end

      context "when the denylist is an array of values" do
        context "when the file extension matches a denylisted extension" do
          let(:extension_denylist) { %w(jpg gif png) }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError, 'You are not allowed to upload "jpg" files, prohibited types: jpg, gif, png')
          end
        end

        context "when the file extension doesn't match a denylisted extension" do
          let(:extension_denylist) { %w(txt doc xls) }

          it "doesn't raise an integrity error" do
            is_expected.to_not raise_error
          end
        end

        context "when the file extension has only the starting part of a denylisted extension string" do
          let(:text_file_name) { 'bork.ttxt' }
          let(:extension_denylist) { %w(txt) }

          it "doesn't raise an integrity error" do
            is_expected.to_not raise_error
          end
        end

        context "when the file extension has only the ending part of a denylisted extension string" do
          let(:text_file_name) { 'bork.txtt' }
          let(:extension_denylist) { %w(txt) }

          it "doesn't raise an integrity error" do
            is_expected.to_not raise_error
          end
        end

        context "when the file has a capitalized extension of a denylisted extension" do
          let(:text_file_name) { 'case.JPG' }
          let(:extension_denylist) { %w(jpg gif png) }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file has an extension which matches a denylisted capitalized extension" do
          let(:text_file_name) { 'test.jpg' }
          let(:extension_denylist) { %w(JPG GIF PNG) }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file has an extension which matches the denylisted extension regular expression" do
          let(:text_file_name) { 'test.jpeg' }
          let(:extension_denylist) { [/jpe?g/, 'gif', 'png'] }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end
      end

      context "when the denylist is a single value" do
        context "when the file has an extension which is equal the denylisted extension string" do
          let(:test_file_name) { 'test.jpeg' }
          let(:extension_denylist) { 'jpeg' }

          it "raises an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end

        context "when the file has a name which matches the denylisted extension regular expression" do
          let(:text_file_name) { 'test.jpeg' }
          let(:extension_denylist) { /jpe?g/ }

          it "raise an integrity error" do
            is_expected.to raise_error(CarrierWave::IntegrityError)
          end
        end
      end
    end

    context "when there is a blacklist" do
      it "uses the blacklist but shows deprecation" do
        allow(uploader).to receive(:extension_blacklist).and_return(%w(jpg gif png))

        expect(ActiveSupport::Deprecation).to receive(:warn).with('#extension_blacklist is deprecated, use #extension_denylist instead.')
        is_expected.to raise_error(CarrierWave::IntegrityError)
      end

      it "looks for extension_denylist first for I18n translation" do
        allow(uploader).to receive(:extension_denylist).and_return(%w(jpg gif png))

        change_locale_and_store_translations(:nl, :errors => {
          :messages => {
            :extension_blacklist_error => "this will not be used",
            :extension_denylist_error => "Het is niet toegestaan om %{extension} bestanden te uploaden; verboden bestandstypes: %{prohibited_types}"
          }
        }) do
          is_expected.to raise_error(CarrierWave::IntegrityError, 'Het is niet toegestaan om "jpg" bestanden te uploaden; verboden bestandstypes: jpg, gif, png')
        end
      end
    end
  end
end
