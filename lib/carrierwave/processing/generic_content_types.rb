module CarrierWave

  ##
  # This module defines a list of generic content-types which might come from user agent
  #
  module GenericContentTypes

    GENERIC_CONTENT_TYPES = %w[
      application-x/octet-stream

      application/
      application/*
      application/binary
      application/download
      application/download-file
      application/downloadfile
      application/force-download
      application/force_download
      application/oclet-stream
      application/octec-stream
      application/octect-stream
      application/octed-stream
      application/octet
      application/octet-binary
      application/octet-stream
      application/octet_stream
      application/octetstream
      application/octlet-stream
      application/save
      application/save-as
      application/stream
      application/unknown
      application/x-download
      application/x-file-download
      application/x-force-download
      application/x-forcedownload
      application/x-octet-stream
      application/x-octets
      application/x-octetstream
      application/x-unknown
      application/x-unknown-application-octet-stream
      application/x-unknown-content-type
      application/x-unknown-octet-stream

      applicaton/octet-stream

      attachment/octet-stream

      bad/type

      binary/
      binary/*
      binary/octec-stream
      binary/octet-stream
      binary/octet_stream
      binary/octetstream

      content-transfer-encoding/binary

      download/file
      download/test

      file/octet-stream
      file/unknown

      multipart/alternative
      multipart/form-data
      multipart/octet-stream

      octet/stream

      type/unknown

      unknown/
      unknown/application
      unknown/data
      unknown/unknown

      x-application/octet-stream
      x-application/octetstream

      x-unknown/octet-stream
      x-unknown/x-unknown
    ]

    def generic_content_type?(content_type)
      GENERIC_CONTENT_TYPES.include? content_type
    end

  end # GenericContentTypes
end # CarrierWave
