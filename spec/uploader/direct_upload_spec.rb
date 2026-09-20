require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:cache_storage) { double('a cache storage') }

  before do
    allow(cache_storage).to receive(:direct_upload_url).and_return('https://example.com/signed')
    allow(uploader).to receive(:cache_storage).and_return(cache_storage)
  end

  describe '#direct_upload' do
    it "tells where and how to upload, and under which name to hand the file back" do
      upload = uploader.direct_upload(filename: 'bork.txt')

      expect(upload.url).to eq('https://example.com/signed')
      expect(upload.method).to eq('PUT')
      expect(upload.headers).to eq({})
      expect(upload.cache_name).to match(%r{\A[\d]+\-[\d]+\-[\d]+\-[\d]{4}/bork\.txt\z})
      expect(upload.to_h.keys).to eq([:url, :method, :headers, :cache_name])
    end

    it "has the file uploaded to where the cache expects it" do
      expect(cache_storage).to receive(:direct_upload_url) do |path, **|
        expect(path).to eq(uploader.send(:cache_path))
        'https://example.com/signed'
      end

      upload = uploader.direct_upload(filename: 'bork.txt')

      expect(upload.cache_name).to eq(uploader.cache_name)
    end

    it "sanitizes the given filename" do
      upload = uploader.direct_upload(filename: '../so me.txt')

      expect(upload.cache_name).to end_with('/so_me.txt')
    end

    it "rejects a filename which leaves nothing to store under" do
      expect { uploader.direct_upload(filename: ' ') }.to raise_error(CarrierWave::InvalidParameter)
    end

    it "gives a new cache id to every upload" do
      names = 2.times.map { uploader.direct_upload(filename: 'bork.txt').cache_name }

      expect(names.first).not_to eq(names.last)
    end

    it "lets the upload stay possible for fog_authenticated_url_expiration by default" do
      uploader_class.fog_authenticated_url_expiration = 60
      expect(cache_storage).to receive(:direct_upload_url).with(anything, hash_including(expires_in: 60))

      uploader.direct_upload(filename: 'bork.txt')
    end

    it "takes how long the upload stays possible" do
      expect(cache_storage).to receive(:direct_upload_url).with(anything, hash_including(expires_in: 10))

      uploader.direct_upload(filename: 'bork.txt', expires_in: 10)
    end

    it "fixes the content type the client has to send, when given one" do
      expect(cache_storage).to receive(:direct_upload_url)
        .with(anything, hash_including(headers: { 'Content-Type' => 'text/plain' }))

      upload = uploader.direct_upload(filename: 'bork.txt', content_type: 'text/plain')

      expect(upload.headers).to eq({ 'Content-Type' => 'text/plain' })
    end

    it "keeps what the storage adds to the headers out of the ones the client is given" do
      allow(cache_storage).to receive(:direct_upload_url) do |_path, headers:, **|
        headers['host'] = 'example.com'
        'https://example.com/signed'
      end

      upload = uploader.direct_upload(filename: 'bork.txt', content_type: 'text/plain')

      expect(upload.headers).to eq({ 'Content-Type' => 'text/plain' })
    end

    context "when the uploader has versions" do
      before { uploader_class.version(:thumb) }

      it "refuses, as nothing would create them" do
        expect { uploader.direct_upload(filename: 'bork.txt') }.to raise_error(RuntimeError, /thumb/)
      end
    end

    context "when the uploader processes what it stores" do
      before { uploader_class.process :do_something }

      it "refuses, as the processing would be skipped" do
        expect { uploader.direct_upload(filename: 'bork.txt') }.to raise_error(RuntimeError, /processing/)
      end

      it "goes ahead when processing is disabled anyway" do
        uploader_class.enable_processing = false

        expect(uploader.direct_upload(filename: 'bork.txt').cache_name).to end_with('/bork.txt')
      end
    end

    context "when the cache is not a storage which can be uploaded to" do
      it "says so" do
        allow(uploader).to receive(:cache_storage).and_call_original

        expect { uploader.direct_upload(filename: 'bork.txt') }
          .to raise_error(NotImplementedError, /CarrierWave::Storage::File/)
      end
    end
  end
end
