require 'spec_helper'
require 'fog'
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
  describe "#filename" do
    subject{ CarrierWave::Storage::Fog::File.new(nil, nil, nil) }

    context "with normal url" do
      before do
        allow(subject).to receive(:url){ 'http://example.com/path/to/foo.txt' }
      end

      it "should extract filename from url" do
        expect(subject.filename).to eq('foo.txt')
      end
    end

    context "when url contains '/' in query string" do
      before do
        allow(subject).to receive(:url){ 'http://example.com/path/to/foo.txt?bar=baz/fubar' }
      end

      it "should extract correct part" do
        expect(subject.filename).to eq('foo.txt')
      end
    end

    context "when url contains multi-byte characters" do
      before do
        allow(subject).to receive(:url){ 'http://example.com/path/to/%E6%97%A5%E6%9C%AC%E8%AA%9E.txt' }
      end

      it "should decode multi-byte characters" do
        expect(subject.filename).to eq('日本語.txt')
      end
    end
  end
end
