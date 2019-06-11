require 'spec_helper'

describe CarrierWave::Uploader::Download do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_id) { '1369894322-345-1234-2255' }
  let(:base_url) { "http://www.example.com" }
  let(:url) { base_url + "/test.jpg" }
  let(:test_file) { File.read(file_path(test_file_name)) }
  let(:test_file_name) { "test.jpg" }

  after { FileUtils.rm_rf(public_path) }

  describe '#download!' do
    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return(cache_id)

      stub_request(:get, "www.example.com/#{test_file_name}")
        .to_return(body: test_file)
    end

    context "when a file was downloaded" do
      before do
        uploader.download!(url)
      end

      it "caches a file" do
        expect(uploader.file).to be_an_instance_of(CarrierWave::SanitizedFile)
      end

      it "'s cached" do
        expect(uploader).to be_cached
      end

      it "stores the cache name" do
        expect(uploader.cache_name).to eq("#{cache_id}/#{test_file_name}")
      end

      it "sets the filename to the file's sanitized filename" do
        expect(uploader.filename).to eq("#{test_file_name}")
      end

      it "moves it to the tmp dir" do
        expect(uploader.file.path).to eq(public_path("uploads/tmp/#{cache_id}/#{test_file_name}"))
        expect(uploader.file.exists?).to be_truthy
      end

      it "sets the url" do
        expect(uploader.url).to eq("/uploads/tmp/#{cache_id}/#{test_file_name}")
      end
    end

    context "with directory permissions set" do
      let(:permissions) { 0777 }

      it "sets permissions" do
        uploader_class.permissions = permissions
        uploader.download!(url)

        expect(uploader).to have_permissions(permissions)
      end

      it "sets directory permissions" do
        uploader_class.directory_permissions = permissions
        uploader.download!(url)

        expect(uploader).to have_directory_permissions(permissions)
      end
    end

    describe "custom downloader" do
      let(:klass) do
        Class.new(CarrierWave::Downloader::Base) {
          def download(url, request_headers={})
          end
        }
      end
      before do
        uploader.downloader = klass
      end

      it "is supported" do
        expect_any_instance_of(klass).to receive(:download).with(url, {})
        uploader.download!(url)
      end
    end
  end
end
