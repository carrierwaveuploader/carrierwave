require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:file_name) { 'test.jpg' }
  let(:file) { File.open(file_path(file_name)) }

  after { FileUtils.rm_rf(public_path) }

  describe '#remove!' do
    let(:stored_file) { double('a stored file') }

    before do
      allow(CarrierWave).to receive(:generate_cache_id).and_return('1390890634-26112-1234-2122')

      cached_file = double('a cached file')
      allow(cached_file).to receive(:delete)

      allow(stored_file).to receive(:path).and_return('/path/to/somewhere')
      allow(stored_file).to receive(:url).and_return('http://www.example.com')
      allow(stored_file).to receive(:identifier).and_return('this-is-me')
      allow(stored_file).to receive(:delete)

      storage = double('a storage engine')
      allow(storage).to receive(:store!).and_return(stored_file)
      allow(storage).to receive(:cache!).and_return(cached_file)
      allow(storage).to receive(:delete_dir!).with("uploads/tmp/#{CarrierWave.generate_cache_id}")

      allow(uploader_class.storage).to receive(:new).and_return(storage)
      uploader.store!(file)
    end

    it "resets the current path" do
      uploader.remove!
      expect(uploader.current_path).to be_nil
    end

    it "should not be cached" do
      uploader.remove!
      expect(uploader).not_to be_cached
    end

    it "resets the url" do
      uploader.cache!(file)
      uploader.remove!
      expect(uploader.url).to be_nil
    end

    it "resets the identifier" do
      uploader.remove!
      expect(uploader.identifier).to be_nil
    end

    it "deletes the file" do
      expect(stored_file).to receive(:delete)
      uploader.remove!
    end

    it "resets the cache_name" do
      uploader.cache!(file)
      uploader.remove!
      expect(uploader.cache_name).to be_nil
    end

    it "does nothing when trying to remove an empty file" do
      expect{ uploader.remove! }.not_to raise_error
    end
  end

end
