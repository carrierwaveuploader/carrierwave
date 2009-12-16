# encoding: utf-8

require 'active_record'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount
    
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      after_save "store_#{column}!"
      before_save "write_#{column}_identifier"
      after_destroy "remove_#{column}!"
    end

    ##
    # Makes the record invalid if the file couldn't be uploaded due to an integrity error
    #
    # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
    #
    # === Note
    #
    # Set this key in your translations file for I18n:
    #
    #     carrierwave:
    #       errors:
    #         integrity: 'Here be an error message'
    #
    def validates_integrity_of(*attrs)
      options = attrs.last.is_a?(Hash) ? attrs.last : {}
      options[:message] ||= I18n.t('carrierwave.errors.integrity', :default => 'is not an allowed type of file.')
      validates_each(*attrs) do |record, attr, value|
        record.errors.add attr, options[:message] if record.send("#{attr}_integrity_error")
      end
    end

    ##
    # Makes the record invalid if the file couldn't be processed (assuming the process failed
    # with a CarrierWave::ProcessingError)
    #
    # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
    #
    # === Note
    #
    # Set this key in your translations file for I18n:
    #
    #     carrierwave:
    #       errors:
    #         processing: 'Here be an error message'
    #
    def validates_processing_of(*attrs)
      options = attrs.last.is_a?(Hash) ? attrs.last : {}
      options[:message] ||= I18n.t('carrierwave.errors.processing', :default => 'failed to be processed.')
      validates_each(*attrs) do |record, attr, value|
        record.errors.add attr, options[:message] if record.send("#{attr}_processing_error")
      end
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.send(:extend, CarrierWave::ActiveRecord)
