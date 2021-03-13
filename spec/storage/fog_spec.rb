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
    subject(:file) { CarrierWave::Storage::Fog::File.new(nil, nil, nil) }

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
  end
end
