# encoding: utf-8

require 'active_model/validator'
require 'active_support/concern'


module CarrierWave

  # == Active Model Presence Validator
  module Validations
    module ActiveModel
      extend ActiveSupport::Concern
      
      class IntegrityValidator < ::ActiveModel::EachValidator
      
        def validate_each(record, attribute, value)
          if record.send("#{attribute}_processing_error")
            options[:message] ||= I18n.t('carrierwave.errors.processing', :default => 'failed to be processed.')
            record.errors.add attribute, :integrity, options
          end
        end
      end
    
      class ProcessingValidator < ::ActiveModel::EachValidator

        def validate_each(record, attribute, value)
          if record.send("#{attribute}_integrity_error")
            options[:message] ||= I18n.t('carrierwave.errors.integrity', :default => 'is not an allowed type of file.')
            record.errors.add attribute, :processing, options.merge!(:value => value)
          end
        end
      end

      module HelperMethods

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
        def validates_integrity_of(*attr_names)
          validates_with IntegrityValidator, _merge_attributes(attr_names)
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
        def validates_processing_of(*attr_names)
          validates_with ProcessingValidator, _merge_attributes(attr_names)
        end
      end
      
      included do
        extend HelperMethods
        include HelperMethods
      end
    end
  end
end
