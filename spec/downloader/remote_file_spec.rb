require 'spec_helper'

describe CarrierWave::Downloader::RemoteFile do
  let(:file) do
    File.open(file_path("test.jpg")).tap { |f| OpenURI::Meta.init(f) }
  end
  subject { CarrierWave::Downloader::RemoteFile.new(file) }

  before do
    subject.base_uri = URI.parse 'http://example.com/test'
    subject.meta_add_field 'content-type', 'image/jpeg'
  end

  it 'sets file extension based on content-type if missing' do
    expect(subject.original_filename).to eq "test.jpeg"
  end

  describe 'with content-disposition' do
    before do
      subject.meta_add_field 'content-disposition', content_disposition
    end

    context 'when filename is quoted' do
      let(:content_disposition){ 'filename="another_test.jpg"' }

      it "reads filename correctly" do
        expect(subject.original_filename).to eq 'another_test.jpg'
      end
    end

    context 'when filename is quoted and empty' do
      let(:content_disposition){ 'filename=""' }

      it "sets file extension based on content-type if missing" do
        expect(subject.original_filename).to eq 'test.jpeg'
      end
    end

    context 'when filename is not quoted and empty' do
      let(:content_disposition){ 'filename=' }

      it "reads filename correctly" do
        expect(subject.original_filename).to eq 'test.jpeg'
      end
    end

    context 'when filename is not quoted' do
      let(:content_disposition){ 'filename=another_test.jpg' }

      it "reads filename correctly" do
        expect(subject.original_filename).to eq 'another_test.jpg'
      end
    end

    context 'when filename is not quoted and terminated by semicolon' do
      let(:content_disposition){ 'filename=another_test.jpg; size=1234' }

      it "reads filename correctly" do
        expect(subject.original_filename).to eq 'another_test.jpg'
      end
    end

    context 'when filename is quoted and contains a semicolon' do
      let(:content_disposition){ 'filename="another;_test.jpg"; size=1234' }

      it "reads filename correctly" do
        expect(subject.original_filename).to eq 'another;_test.jpg'
      end
    end
  end
end
