unless defined?(FOG_CREDENTIALS)

  credentials = []

  if Fog.mocking?
    # Local and Rackspace don't have fog double support yet
    mappings = {
      'AWS'       => [:aws_access_key_id, :aws_secret_access_key],
      'Google'    => [:google_storage_access_key_id, :google_storage_secret_access_key],
      # 'Local'     => [:local_root],
      # 'Rackspace' => [:rackspace_api_key, :rackspace_username]
    }

    mappings.each do |provider, keys|
      data = {:provider => provider}
      keys.each do |key|
        data[key] = key.to_s
      end
      credentials << data
    end

    FOG_CREDENTIALS = credentials
  else
    Fog.credential = :carrierwave

    mappings = {
      'AWS'       => [:aws_access_key_id, :aws_secret_access_key],
      'Google'    => [:google_storage_access_key_id, :google_storage_secret_access_key],
      'Local'     => [:local_root],
      'Rackspace' => [:rackspace_api_key, :rackspace_username]
    }

    mappings.each do |provider, keys|
      unless (creds = Fog.credentials.reject {|key, value| ![*keys].include?(key)}).empty?
        data = {:provider => provider}
        keys.each do |key|
          data[key] = creds[key]
        end
        credentials << data
      end
    end

    FOG_CREDENTIALS = credentials
  end

end
