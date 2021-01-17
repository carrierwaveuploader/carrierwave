require 'spec_helper'
require 'active_support/json'

describe CarrierWave::Uploader do

  let(:uploader) { MyCoolUploader.new }

  before { class MyCoolUploader < CarrierWave::Uploader::Base; end }

  after do
    FileUtils.rm_rf(public_path)
    Object.send(:remove_const, "MyCoolUploader") if defined?(::MyCoolUploader)
  end

  let(:cache_id) { '1369894322-345-1234-2255' }
  let(:test_file) { File.open(file_path(test_file_name)) }
  let(:test_file_name) { 'test.jpg' }

  before { allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id) }

  describe '#url' do
    subject(:url) { uploader.url }

    it { is_expected.to be_nil }

    it "doesn't raise exception when hash specified as argument" do
      expect { uploader.url({}) }.not_to raise_error
    end

    it "encodes the path of a file without an asset host" do
      uploader.cache!(File.open(file_path('test+.jpg')))
      is_expected.to eq("/uploads/tmp/#{cache_id}/test%2B.jpg")
    end

    context "with a cached file" do
      before { uploader.cache!(test_file) }

      it "gets the directory relative to public, prepending a slash" do
        is_expected.to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
      end

      describe "File#url" do
        before do
          allow(uploader.file).to receive(:url).and_return(file_url)
        end

        context "when present" do
          let(:file_url) { 'http://www.example.com/someurl.jpg' }

          it { is_expected.to eq(file_url) }
        end

        context "when blank" do
          let(:file_url) { '' }

          it "returns the relative path" do
            is_expected.to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
          end
        end
      end
    end

    context "File#url" do
      let(:file_class) { FileX = Class.new }
      let(:file) { file_class.new }

      before do
        allow(uploader).to receive(:file).and_return(file)
      end

      it "does not accept arguments" do
        file.define_singleton_method(:url) { true }
        uploader.url
      end

      it "does accept arguments" do
        file.define_singleton_method(:url) { |x = true| x }
        expect(file).to receive(:url).once.and_call_original
        uploader.url
      end
    end

    describe "(:thumb)" do
      subject { uploader.url(:thumb) }

      it "raises ArgumentError when version doesn't exist" do
        expect { uploader.url(:thumb) }.to raise_error(ArgumentError)
      end

      context "when version is specified" do
        before do
          MyCoolUploader.version(:thumb)
          uploader.cache!(test_file)
        end

        it "doesn't raise ArgumentError when versions version exists" do
          expect { uploader.url(:thumb) }.not_to raise_error
        end

        it "gets the directory relative to public for a specific version" do
          is_expected.to eq("/uploads/tmp/#{cache_id}/thumb_#{test_file_name}")
        end

        describe "asset_host" do
          before { uploader.class.configure { |config| config.asset_host = asset_host } }

          context "when set as a string" do
            let(:asset_host) { "http://foo.bar" }

            it "prepends the string" do
              is_expected.to eq("#{asset_host}/uploads/tmp/#{cache_id}/thumb_#{test_file_name}")
            end

            describe "encoding" do
              let(:test_file_name) { 'test+.jpg' }

              it "encodes the path of a file" do
                is_expected.to eq("#{asset_host}/uploads/tmp/#{cache_id}/thumb_test%2B.jpg")
              end

              it "double-encodes the path of an available File#url" do
                url = 'http://www.example.com/directory%2Bname/another%2Bdirectory/some%2Burl.jpg'
                allow(uploader.file).to receive(:url).and_return(url)

                expect(uploader.url).to eq(url)
              end
            end
          end

          context "when set as a proc" do
            let(:asset_host) { proc { "http://foo.bar" } }

            it "prepends the result of proc" do
              is_expected.to eq("#{asset_host.call}/uploads/tmp/#{cache_id}/thumb_#{test_file_name}")
            end

            describe "encoding" do
              let(:test_file_name) { 'test+.jpg' }

              it { is_expected.to eq("#{asset_host.call}/uploads/tmp/#{cache_id}/thumb_test%2B.jpg") }
            end
          end

          context "when set as nil" do
            let(:asset_host) { nil }

            context "when base_path is set" do
              let(:base_path) { "/base_path" }

              before do
                uploader.class.configure do |config|
                  config.base_path = base_path
                end
              end

              it "prepends the config option 'base_path'" do
                is_expected.to eq("#{base_path}/uploads/tmp/#{cache_id}/thumb_#{test_file_name}")
              end
            end
          end
        end
      end

      context "when the version is nested" do
        subject { uploader.url(:thumb, :mini) }

        before do
          MyCoolUploader.version(:thumb) { version(:mini) }
          uploader.cache!(test_file)
        end

        it "gets the directory relative to public for a nested version" do
          is_expected.to eq("/uploads/tmp/#{cache_id}/thumb_mini_#{test_file_name}")
        end
      end
    end
  end

  describe '#to_json' do
    subject(:parsed_json) { JSON.parse(to_json) }

    let(:to_json) { uploader.to_json }

    context "(:thumb)" do
      before { MyCoolUploader.version(:thumb) }

      it { expect(parsed_json.keys).to include("url") }
      it { expect(parsed_json.keys).to include("thumb") }
      it { expect(parsed_json["url"]).to be_nil }
      it { expect(parsed_json["thumb"].keys).to include("url") }
      it { expect(parsed_json["thumb"]["url"]).to be_nil }

      context "with a cached_file" do
        before { uploader.cache!(test_file) }

        it { expect(parsed_json.keys).to include("thumb") }
        it { expect(parsed_json["thumb"]).to eq({"url" => "/uploads/tmp/#{cache_id}/thumb_#{test_file_name}"}) }
      end
    end

    context "with cached file" do
      before { uploader.cache!(test_file) }

      it "returns a hash including a cached URL" do
        is_expected.to eq({"url" => "/uploads/tmp/#{cache_id}/#{test_file_name}"})
      end
    end

    it "allows an options parameter to be passed in" do
      expect { uploader.to_json({:some => 'options'}) }.not_to raise_error
    end
  end

  describe '#to_xml' do
    subject(:parsed_xml) { Hash.from_xml(to_xml) }

    let(:to_xml) { uploader.to_xml }

    it "returns a hash with a blank URL" do
      is_expected.to eq({"uploader" => {"url" => nil}})
    end

    context "with cached file" do
      before { uploader.cache!(test_file) }

      it "returns a hash including a cached URL" do
        is_expected.to eq({"uploader" => {"url" => "/uploads/tmp/#{cache_id}/#{test_file_name}"}})
      end

      context "with an array of uploaders" do
        let(:to_xml) { [uploader].to_xml }

        it "returns a hash including an array with a cached URL" do
          is_expected.to have_value([{"url"=>"/uploads/tmp/#{cache_id}/#{test_file_name}"}])
        end
      end
    end

    describe "(:thumb)" do
      before { MyCoolUploader.version(:thumb) }

      context "with cached file" do
        before { uploader.cache!(test_file) }

        it "returns a hash including a cached URL of a version" do
          expect(parsed_xml["uploader"]["thumb"]).to eq({"url" => "/uploads/tmp/#{cache_id}/thumb_#{test_file_name}"})
        end
      end
    end
  end

  describe '#to_s' do
    subject { uploader.to_s }

    it { is_expected.to eq('') }

    context "with cached file" do
      before { uploader.cache!(test_file) }

      it "gets the directory relative to public, prepending a slash" do
        is_expected.to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
      end

      describe "File#url" do
        before { allow(uploader.file).to receive(:url).and_return(url) }

        context "when present" do
          let(:url) { 'http://www.example.com/someurl.jpg' }

          it { is_expected.to eq(url) }
        end
      end
    end
  end
end
