require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }

  after { FileUtils.rm_rf(public_path) }

  describe 'with a default url' do
    before do
      uploader_class.class_eval do
        version :thumb
        def default_url
          ['http://someurl.example.com', version_name].compact.join('/')
        end
      end
    end

    describe '#blank?' do
      subject { uploader }

      it "is blank by default" do
        is_expected.to be_blank
      end
    end

    describe '#current_path' do
      subject { uploader.current_path }

      it { is_expected.to be_nil }
    end

    describe '#url' do
      let(:url_example) { "http://someurl.example.com" }

      it "returns the default url" do
        expect(uploader.url).to eq(url_example)
      end

      it "returns the default url with version when given" do
        expect(uploader.url(:thumb)).to eq("#{url_example}/thumb")
      end
    end

    describe '#cache!' do
      let(:cache_id) { '1369894322-345-1234-2255' }
      let(:file_name) { 'test.jpg' }

      subject { uploader }

      before do
        allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id)
        uploader.cache!(File.open(file_path(file_name)))
      end

      it "caches a file" do
        expect(uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
      end

      it "is cached" do
        expect(uploader).to be_cached
      end

      it "isn't blank" do
        expect(uploader).not_to be_blank
      end

      it "sets the current_path" do
        expect(uploader.current_path).to eq(public_path("uploads/tmp/#{cache_id}/#{file_name}"))
      end

      it "sets the url" do
        expect(uploader.url).to eq ("/uploads/tmp/#{cache_id}/#{file_name}")
      end
    end
  end
end
