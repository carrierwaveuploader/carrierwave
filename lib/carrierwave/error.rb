module CarrierWave
  class UploadError < StandardError; end
  class IntegrityError < UploadError; end
  class InvalidParameter < UploadError; end
  class ProcessingError < UploadError; end
  class DownloadError < UploadError; end
end
