# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader_class.configure do |config|

      config.fog_credentials = {
          :provider               => 'AWS',         # required
          :aws_access_key_id      => 'XXXX',        # required
          :aws_secret_access_key  => 'YYYY',        # required
          :region                 => 'us-east-1'    # optional, defaults to 'us-east-1'
      }

      config.fog_directory = "defaultbucket"
    end

    @uploader = @uploader_class.new
    @uploader_overridden = @uploader_class.new
    @uploader_overridden.fog_credentials = {
        :provider               => 'AWS',               # required
        :aws_access_key_id      => 'ZZZZ',              # required
        :aws_secret_access_key  => 'AAAA',              # required
        :region                 => 'us-east-2'          # optional, defaults to 'us-east-1'
    }
    @uploader_overridden.fog_public = false
  end

  describe 'fog_credentials' do
    it 'should reflect the standard value if no override done' do
      expect(@uploader.fog_credentials).to be_a(Hash)
      expect(@uploader.fog_credentials[:provider]).to be_eql('AWS')
      expect(@uploader.fog_credentials[:aws_access_key_id]).to be_eql('XXXX')
      expect(@uploader.fog_credentials[:aws_secret_access_key]).to be_eql('YYYY')
      expect(@uploader.fog_credentials[:region]).to be_eql('us-east-1')
    end

    it 'should reflect the new values in uploader class with override' do
      expect(@uploader_overridden.fog_credentials).to be_a(Hash)
      expect(@uploader_overridden.fog_credentials[:provider]).to be_eql('AWS')
      expect(@uploader_overridden.fog_credentials[:aws_access_key_id]).to be_eql('ZZZZ')
      expect(@uploader_overridden.fog_credentials[:aws_secret_access_key]).to be_eql('AAAA')
      expect(@uploader_overridden.fog_credentials[:region]).to be_eql('us-east-2')
    end
  end

  describe 'fog_directory' do
    it 'should reflect the standard value if no override done' do
      expect(@uploader.fog_directory).to be_eql('defaultbucket')
    end

    it 'should reflect the standard value in overridden object because property is not overridden' do
      expect(@uploader_overridden.fog_directory).to be_eql('defaultbucket')
    end
  end

  describe 'fog_public' do
    it 'should reflect the standard value if no override done' do
      expect(@uploader.fog_public).to be_eql(true)
    end

    it 'should reflect the standard value in overridden object because property is not overridden' do
      expect(@uploader_overridden.fog_public).to be_eql(false)
    end
  end
end