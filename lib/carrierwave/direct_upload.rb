module CarrierWave
  ##
  # What a client needs to upload a file straight into the cache. See
  # CarrierWave::Uploader::DirectUpload#direct_upload.
  #
  class DirectUpload
    attr_reader :url, :method, :headers, :cache_name

    def initialize(url:, cache_name:, headers: {}, method: 'PUT')
      @url = url
      @cache_name = cache_name
      @headers = headers
      @method = method
    end

    def to_h
      { url: url, method: method, headers: headers, cache_name: cache_name }
    end
  end # DirectUpload
end # CarrierWave
