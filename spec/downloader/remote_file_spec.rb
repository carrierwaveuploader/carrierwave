require 'spec_helper'

describe CarrierWave::Downloader::RemoteFile do
  subject { CarrierWave::Downloader::RemoteFile.new(file) }
  let(:file) do
    Net::HTTPSuccess.new('1.0', '200', "").tap do |response|
      response.body = File.read(file_path("test.jpg"))
      response.instance_variable_set(:@read, true)
      response.uri = URI.parse 'http://example.com/test'
      response['content-type'] = 'image/jpeg'
      response['vary'] = 'Accept-Encoding'
    end
  end

  context 'with Net::HTTPResponse instance' do
    it 'returns content type' do
      expect(subject.content_type).to eq 'image/jpeg'
    end

    it 'returns header' do
      expect(subject.headers['vary']).to eq 'Accept-Encoding'
    end

    it 'returns URI' do
      expect(subject.uri.to_s).to eq 'http://example.com/test'
    end
  end

  {
    '204' => Net::HTTPNoContent,
    '205' => Net::HTTPResetContent
  }.each do |response_code, response_class|
    context "with a #{response_class} instance" do
      let!(:file) do
        response_class.new('1.0', response_code, '').tap do |response|
          response.reading_body(StringIO.new, true) {}
        end
      end

      it 'raises CarrierWave::DownloadError' do
        expect { subject }.to raise_error(CarrierWave::DownloadError, 'could not download file: No Content')
      end
    end
  end

  context 'with OpenURI::Meta instance' do
    let(:file) do
      File.open(file_path("test.jpg")).tap { |f| OpenURI::Meta.init(f) }.tap do |file|
        file.base_uri = URI.parse 'http://example.com/test'
        file.meta_add_field 'content-type', 'image/jpeg'
        file.meta_add_field 'vary', 'Accept-Encoding'
      end
    end
    it 'returns content type' do
      expect(subject.content_type).to eq 'image/jpeg'
    end

    it 'returns header' do
      expect(subject.headers['vary']).to eq 'Accept-Encoding'
    end

    it 'returns URI' do
      expect(subject.uri.to_s).to eq 'http://example.com/test'
    end
  end

  describe '#original_filename' do
    let(:content_disposition){ nil }
    before do
      file['content-disposition'] = content_disposition if content_disposition
    end

    it 'sets file extension based on content-type if missing' do
      expect(subject.original_filename).to eq "test.jpg"
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
        expect(subject.original_filename).to eq 'test.jpg'
      end
    end

    context 'when filename is not quoted and empty' do
      let(:content_disposition){ 'filename=' }

      it "reads filename correctly" do
        expect(subject.original_filename).to eq 'test.jpg'
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

    context 'when the path contains a literal plus sign' do
      before { file.uri = URI.parse('http://example.com/my+test.jpg') }

      it "keeps the plus sign (#2590)" do
        expect(subject.original_filename).to eq 'my+test.jpg'
      end
    end

    context 'when the path contains an escaped plus sign' do
      before { file.uri = URI.parse('http://example.com/my%2Btest.jpg') }

      it "decodes it to a plus sign" do
        expect(subject.original_filename).to eq 'my+test.jpg'
      end
    end

    context 'when the path contains escaped non-ascii characters' do
      before { file.uri = URI.parse('http://example.com/%E3%81%82.jpg') }

      it "decodes them" do
        expect(subject.original_filename).to eq 'あ.jpg'
      end
    end

    context 'when the path contains an escaped space' do
      before { file.uri = URI.parse('http://example.com/my%20test.jpg') }

      it "decodes it to a space" do
        expect(subject.original_filename).to eq 'my test.jpg'
      end
    end
  end

  describe 'round-tripping a stored file (#2590, #2631)' do
    # Feeding a generated url back into remote_url= is common when duplicating a record
    let(:helper) { Object.new.extend(CarrierWave::Utilities::Uri) }
    let(:downloader) { CarrierWave::Downloader::Base.new(nil) }

    ['test+x.pdf', '100%.jpg', 'a b.jpg', 'あ.jpg', 'a_b-c.jpg'].each do |name|
      it "preserves #{name.inspect} through url generation and download" do
        url = 'https://bucket.s3.amazonaws.com' + helper.send(:encode_path, "/uploads/#{name}")
        path = downloader.process_uri(url).path
        expect(helper.send(:decode_path, File.basename(path))).to eq name
      end
    end
  end
end
