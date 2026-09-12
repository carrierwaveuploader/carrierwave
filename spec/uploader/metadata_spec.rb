require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:test_file) { File.open(file_path('test.jpg')) }

  after { FileUtils.rm_rf(public_path) }

  describe '#metadata' do
    it "should be empty when nothing is recorded" do
      expect(uploader.metadata).to eq({})
    end

    it "should stringify the keys of what is assigned" do
      uploader.metadata = { size: 123 }
      expect(uploader.metadata).to eq('size' => 123)
    end

    it "should be taken from the parent's record for a version" do
      uploader_class.version(:thumb)
      uploader.metadata = { 'versions' => { 'thumb' => { 'size' => 123 } } }
      expect(uploader.thumb.metadata).to eq('size' => 123)
    end

    it "should be empty for a version the parent's record doesn't mention" do
      uploader_class.version(:thumb)
      uploader.metadata = { 'versions' => {} }
      expect(uploader.thumb.metadata).to eq({})
    end

    it "should be dropped when a new file is cached" do
      uploader.metadata = { 'size' => 123 }
      uploader.cache!(test_file)
      expect(uploader.metadata).to eq({})
    end

    it "should be dropped when the versions are recreated" do
      uploader.store!(test_file)
      uploader.metadata = { 'size' => 123 }
      uploader.recreate_versions!
      expect(uploader.metadata).to eq({})
    end
  end

  describe '#build_metadata' do
    before do
      uploader_class.version(:thumb)
      uploader_class.version(:preview, if: :preview?)
      uploader_class.class_eval { def preview?(file); false; end }
      uploader.cache!(test_file)
    end

    it "should collect the facts about the file being stored" do
      expect(uploader.build_metadata).to include(
        'filename' => 'test.jpg',
        'size' => uploader.size,
        'content_type' => uploader.content_type
      )
    end

    it "should only collect the versions which are created" do
      expect(uploader.build_metadata['versions'].keys).to eq ['thumb']
    end

    it "should collect the facts about the versions" do
      expect(uploader.build_metadata['versions']['thumb']).to include('filename' => 'thumb_test.jpg')
    end
  end

  describe '#size' do
    it "should be taken from the record" do
      uploader.metadata = { 'size' => 123 }
      expect(uploader.size).to eq 123
    end

    it "should be asked to the file when nothing is recorded" do
      uploader.cache!(test_file)
      expect(uploader.size).to eq test_file.size
    end
  end

  describe '#content_type' do
    it "should be taken from the record" do
      uploader.metadata = { 'content_type' => 'image/jpeg' }
      expect(uploader.content_type).to eq 'image/jpeg'
    end

    it "should be asked to the file when nothing is recorded" do
      uploader.cache!(test_file)
      expect(uploader.content_type).to eq 'application/octet-stream'
    end
  end

  describe '#version_active?' do
    before do
      uploader_class.version(:thumb, if: :thumb?)
      uploader.retrieve_from_store!('test.jpg')
    end

    it "should be taken from the record instead of asking the condition again" do
      expect(uploader).not_to receive(:thumb?)
      uploader.metadata = { 'versions' => { 'thumb' => {} } }
      expect(uploader.version_active?(:thumb)).to be true
    end

    it "should be false for a version which was not created, whatever the condition says now" do
      allow(uploader).to receive(:thumb?).and_return(true)
      uploader.metadata = { 'versions' => {} }
      expect(uploader.version_active?(:thumb)).to be false
    end

    it "should be false for a version which no longer exists in the uploader" do
      uploader.metadata = { 'versions' => { 'gone' => {} } }
      expect(uploader.version_active?(:gone)).to be false
    end

    it "should ask the condition when nothing is recorded" do
      expect(uploader).to receive(:thumb?).at_least(:once).and_return(true)
      expect(uploader.version_active?(:thumb)).to be true
    end
  end

  describe '#store_path' do
    before { uploader_class.version(:thumb) }

    it "should use the recorded filename" do
      uploader.metadata = { 'filename' => 'test.png', 'versions' => { 'thumb' => { 'filename' => 'thumb_test.png' } } }
      uploader.retrieve_from_store!('test.jpg')
      expect(uploader.store_path).to eq 'uploads/test.png'
      expect(uploader.thumb.store_path).to eq 'uploads/thumb_test.png'
    end

    it "should be used to retrieve the file from the storage" do
      uploader.metadata = { 'filename' => 'test.png', 'versions' => { 'thumb' => { 'filename' => 'thumb_test.png' } } }
      uploader.retrieve_from_store!('test.jpg')
      expect(uploader.path).to eq public_path('uploads/test.png')
      expect(uploader.thumb.path).to eq public_path('uploads/thumb_test.png')
    end

    it "should be derived as usual when nothing is recorded" do
      uploader.retrieve_from_store!('test.jpg')
      expect(uploader.store_path).to eq 'uploads/test.jpg'
      expect(uploader.thumb.store_path).to eq 'uploads/thumb_test.jpg'
    end

    it "should be derived as usual for a file other than the stored one" do
      uploader.metadata = { 'filename' => 'test.png' }
      uploader.retrieve_from_store!('test.jpg')
      expect(uploader.store_path('kebab.gif')).to eq 'uploads/kebab.gif'
    end
  end
end
