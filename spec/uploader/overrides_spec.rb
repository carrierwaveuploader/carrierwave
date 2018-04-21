require 'spec_helper'

describe CarrierWave::Uploader do
  let(:uploader_class) do
    Class.new(CarrierWave::Uploader::Base).tap do |uc|
      uc.configure do |config|

        config.fog_provider = 'fog/aws'
        config.fog_credentials = {
          :provider               => 'AWS',         # required
          :aws_access_key_id      => 'XXXX',        # required
          :aws_secret_access_key  => 'YYYY',        # required
          :region                 => 'us-east-1'    # optional, defaults to 'us-east-1'
        }

        config.fog_directory = "defaultbucket"
      end
    end
  end

  let(:uploader) { uploader_class.new }

  let(:uploader_overridden) do
    uploader_class.tap do |uo|
      uo.fog_credentials = {
        :provider               => 'AWS',               # required
        :aws_access_key_id      => 'ZZZZ',              # required
        :aws_secret_access_key  => 'AAAA',              # required
        :region                 => 'us-east-2'          # optional, defaults to 'us-east-1'
      }
      uo.fog_public = false
    end
  end

  describe 'fog_credentials' do
    describe 'reflects the standard value if no override done' do
      it { expect(uploader.fog_credentials).to be_a(Hash) }
      it { expect(uploader.fog_credentials[:provider]).to be_eql('AWS') }
      it { expect(uploader.fog_credentials[:aws_access_key_id]).to be_eql('XXXX') }
      it { expect(uploader.fog_credentials[:aws_secret_access_key]).to be_eql('YYYY') }
      it { expect(uploader.fog_credentials[:region]).to be_eql('us-east-1') }
    end

    describe 'reflects the new values in uploader class with override' do
      it { expect(uploader_overridden.fog_credentials).to be_a(Hash) }
      it { expect(uploader_overridden.fog_credentials[:provider]).to be_eql('AWS') }
      it { expect(uploader_overridden.fog_credentials[:aws_access_key_id]).to be_eql('ZZZZ') }
      it { expect(uploader_overridden.fog_credentials[:aws_secret_access_key]).to be_eql('AAAA') }
      it { expect(uploader_overridden.fog_credentials[:region]).to be_eql('us-east-2') }
    end
  end

  describe 'fog_directory' do
    it 'reflects the standard value if no override done' do
      expect(uploader.fog_directory).to be_eql('defaultbucket')
    end

    it 'reflects the standard value in overridden object because property is not overridden' do
      expect(uploader_overridden.fog_directory).to be_eql('defaultbucket')
    end
  end

  describe 'fog_public' do
    it 'reflects the standard value if no override done' do
      expect(uploader.fog_public).to be_eql(true)
    end

    it 'reflects the standard value in overridden object because property is not overridden' do
      expect(uploader_overridden.fog_public).to be_eql(false)
    end
  end
end
