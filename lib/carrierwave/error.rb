module CarrierWave
  class UploadError < StandardError; end

  class IntegrityError < UploadError
    # @return [String] Returns the error message which can safely be exposed to
    # the user.
    attr_reader :public_message

    # Construct a new IntegrityError object, optionally passing in messages.
    #
    # @param error_message [String] Optional message.
    #
    # @param public_error_message [String] Error message which can safely be
    # exposed to the user. If it is not specified, it fallbacks to
    # error_message. If error_message is not specified, it fallbacks to
    # a default message translated for the current locale.
    def initialize(error_message = nil, public_error_message = error_message)
      super error_message
      @public_message = if public_error_message.nil?
                          I18n.t(:"errors.messages.carrierwave_integrity_error")
                        else
                          public_error_message
                        end
    end
  end

  class InvalidParameter < UploadError; end

  class ProcessingError < UploadError
    # @return [String] Returns the error message which can safely be exposed to
    # the user.
    attr_reader :public_message

    # Construct a new IntegrityError object, optionally passing in messages.
    #
    # @param error_message [String] Optional message.
    #
    # @param public_error_message [String] Error message which can safely be
    # exposed to the user. If it is not specified, it fallbacks to
    # error_message. If error_message is not specified, it fallbacks to
    # a default message translated for the current locale.
    def initialize(error_message = nil, public_error_message = error_message)
      super error_message
      @public_message = if public_error_message.nil?
                          I18n.t(:"errors.messages.carrierwave_processing_error")
                        else
                          public_error_message
                        end
    end
  end

  class DownloadError < UploadError
    # @return [String] Returns the error message which can safely be exposed to
    # the user.
    attr_reader :public_message

    # Construct a new IntegrityError object, optionally passing in messages.
    #
    # @param error_message [String] Optional message.
    #
    # @param public_error_message [String] Error message which can safely be
    # exposed to the user. If it is not specified, it fallbacks to
    # error_message. If error_message is not specified, it fallbacks to
    # a default message translated for the current locale.
    def initialize(error_message = nil, public_error_message = error_message)
      super error_message
      @public_message = if public_error_message.nil?
                          I18n.t(:"errors.messages.carrierwave_download_error")
                        else
                          public_error_message
                        end
    end
  end

  class UnknownStorageError < StandardError; end
end
