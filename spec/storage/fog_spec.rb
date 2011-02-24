# encoding: utf-8

require 'spec_helper'
require 'open-uri'

# figure out what tests should be runnable (based on available credentials and mocks)
credentials = []

if Fog.mocking?
  mappings = {
    'AWS'       => [:aws_access_key_id, :aws_secret_access_key],
    'Google'    => [:google_storage_access_key_id, :google_storage_secret_access_key],
    # pending fog mock support
    # 'Local'     => [:local_root],
    # 'Rackspace' => [:rackspace_api_key, :rackspace_username]
  }

  for provider, keys in mappings
    data = {:provider => provider}
    for key in keys
      data[key] = key.to_s
    end
    credentials << data
  end
else
  Fog.credential = :carrierwave

  mappings = {
    'AWS'       => [:aws_access_key_id, :aws_secret_access_key],
    'Google'    => [:google_storage_access_key_id, :google_storage_secret_access_key],
    'Local'     => [:local_root],
    'Rackspace' => [:rackspace_api_key, :rackspace_username]
  }

  for provider, keys in mappings
    unless (creds = Fog.credentials.reject {|key, value| ![*keys].include?(key)}).empty?
      data = {:provider => provider}
      for key in keys
        data[key] = creds[key]
      end
      credentials << data
    end
  end
end

# run everything we have credentials for
for credential in credentials
  fog_tests(credential)
end
