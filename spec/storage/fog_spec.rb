require 'spec_helper'
require 'fog/aws'
require 'fog/google'
require 'fog/local'
require 'fog/rackspace'

unless ENV['REMOTE'] == 'true'
  Fog.mock!
end

require_relative './fog_credentials' # after Fog.mock!
require_relative './fog_helper'

describe CarrierWave::Storage::Fog do
  FOG_CREDENTIALS.each do |credential|
    fog_tests(credential)
  end

  describe '.eager_load' do
    after do
      CarrierWave::Storage::Fog.connection_cache.clear
      CarrierWave::Uploader::Base.fog_credentials = nil
    end

    it "caches Fog::Storage instance" do
      CarrierWave::Uploader::Base.fog_credentials = {
        provider: 'AWS', aws_access_key_id: 'foo', aws_secret_access_key: 'bar'
      }
      expect { CarrierWave::Storage::Fog.eager_load }.
        to change { CarrierWave::Storage::Fog.connection_cache }
    end

    it "does nothing when fog_credentials is empty" do
      CarrierWave::Uploader::Base.fog_credentials = {}
      expect { CarrierWave::Storage::Fog.eager_load }.
        not_to change { CarrierWave::Storage::Fog.connection_cache }
    end
  end

  describe CarrierWave::Storage::Fog::File do
    subject(:file) { CarrierWave::Storage::Fog::File.new(uploader, base, path) }

    let(:uploader) { instance_double(CarrierWave::Uploader::Base, fog_attributes: {some: :attribute}, fog_public: true, fog_acl: fog_acl, fog_credentials: {provider: 'AWS'}) }
    let(:base) { instance_double(CarrierWave::Storage::Fog) }
    let(:path) { 'path/to/file.txt' }
    let(:fog_acl) { true }

    describe "#filename" do
      subject(:filename) { file.filename }

      before { allow(file).to receive(:url).and_return(url) }

      context "with normal url" do
        let(:url) { 'http://example.com/path/to/foo.txt' }

        it "extracts filename from url" do
          is_expected.to eq('foo.txt')
        end
      end

      context "when url contains '/' in query string" do
        let(:url){ 'http://example.com/path/to/foo.txt?bar=baz/fubar' }

        it "extracts correct part" do
          is_expected.to eq('foo.txt')
        end
      end

      context "when url contains multi-byte characters" do
        let(:url) { 'http://example.com/path/to/%E6%97%A5%E6%9C%AC%E8%AA%9E.txt' }

        it "decodes multi-byte characters" do
          is_expected.to eq('日本語.txt')
        end
      end
    end

    describe "#basename" do
      subject(:basename) { file.basename }

      before { allow(file).to receive(:filename).and_return(filename) }

      context "when file has complicated extensions" do
        let(:filename) { "complex.filename.tar.gz" }

        it "return correct basename" do
          is_expected.to eq("complex.filename")
        end
      end

      context "when file has simple extension" do
        let(:filename) { "simple.extension" }

        it "return correct basename" do
          is_expected.to eq("simple")
        end
      end

      context "when file has no extension" do
        let(:filename) { "filename" }

        it "return correct basename" do
          is_expected.to eq("filename")
        end
      end
    end

    describe "#extension" do
      subject(:extension) { file.extension }

      before { allow(file).to receive(:filename).and_return(filename) }

      %w[gz bz2 z lz xz].each do |ext|
        context "when file has complicated extensions (tar.#{ext})" do
          let(:filename) { "complex.filename.tar.#{ext}" }

          it "return correct extension" do
            is_expected.to eq("tar.#{ext}")
          end
        end
      end

      context "when file has simple extension" do
        let(:filename) { "simple.extension" }

        it "return correct extension" do
          is_expected.to eq("extension")
        end
      end

      context "when file has no extension" do
        let(:filename) { "filename" }

        it "return correct extension" do
          is_expected.to eq("")
        end
      end
    end

    describe '#store' do
      subject(:store) { file.store(new_file) }

      let(:fog_file) { double('Fog::File') }
      let(:directory_files) { double('files', head: fog_file) }
      let(:directory) { double('directory', files: directory_files) }
      let(:fog_directory) { 'a-wonderful-fog-directory' }

      before do
        allow(uploader).to receive(:fog_directory).and_return(fog_directory)
        connection = double('connection', directories: double('directories', new: directory))
        allow(base).to receive(:connection).and_return(connection)
      end

      context 'when fog_acl is true' do
        let(:fog_acl) { true }

        context 'and new_file is a Fog::File' do
          let(:new_file) { CarrierWave::Storage::Fog::File.new(uploader, base, path) }

          it 'stores the file' do
            expected_options = {some: :attribute, "x-amz-acl" => "public-read"}
            expect(fog_file).to receive(:copy).with(fog_directory, path, expected_options)

            expect(store).to be true
          end
        end

        context 'and new_file is a SanitizedFile' do
          let(:new_file) { CarrierWave::SanitizedFile.new(file_path('test.jpg')) }

          before do
            # stub this to always return the same value so that the equality comparison works
            allow(new_file).to receive(:to_file).and_return(File.new(file_path('test.jpg')))
          end

          it 'stores the file' do
            fog_create_file_params = {
              body: new_file.to_file,
              content_type: 'application/octet-stream',
              key: path,
              public: true,
              some: :attribute
            }
            expect(directory_files).to receive(:create).with(fog_create_file_params)

            expect(store).to be true
          end
        end
      end

      context 'when fog_acl is false' do
        let(:fog_acl) { false }

        context 'and new_file is a Fog::File' do
          let(:new_file) { CarrierWave::Storage::Fog::File.new(uploader, base, path) }

          it 'stores the file' do
            expected_options = {some: :attribute}
            expect(fog_file).to receive(:copy).with(fog_directory, path, expected_options)

            expect(store).to be true
          end
        end

        context 'and new_file is a SanitizedFile' do
          let(:new_file) { CarrierWave::SanitizedFile.new(file_path('test.jpg')) }

          before do
            # stub this to always return the same value so that the equality comparison works
            allow(new_file).to receive(:to_file).and_return(File.new(file_path('test.jpg')))
          end

          it 'stores the file' do
            fog_create_file_params = {
              body: new_file.to_file,
              content_type: 'application/octet-stream',
              key: path,
              some: :attribute
            }
            expect(directory_files).to receive(:create).with(fog_create_file_params)

            expect(store).to be true
          end
        end
      end
    end
  end
end
