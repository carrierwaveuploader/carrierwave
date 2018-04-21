require 'spec_helper'
require 'fog/aws'
require 'fog/google'
require 'fog/local'
require 'fog/rackspace'
require 'carrierwave/storage/fog'

unless ENV['REMOTE'] == 'true'
  Fog.mock!
end

require_relative './fog_credentials' # after Fog.mock!
require_relative './fog_helper'

FOG_CREDENTIALS.each do |credential|
  fog_tests(credential)
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
