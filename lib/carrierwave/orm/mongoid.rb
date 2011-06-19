# encoding: utf-8

require 'mongoid'
require 'carrierwave/validations/active_model'

module CarrierWave
  module Mongoid
    include CarrierWave::Mount
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      options[:mount_on] ||= "#{column}_filename"
      field options[:mount_on]

      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of  column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      after_save      :"store_#{column}!"
      before_save     :"write_#{column}_identifier"
      after_destroy   :"remove_#{column}!"
      before_update   :"store_previous_model_for_#{column}"
      after_save      :"remove_previously_stored_#{column}"

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column

          # Note (Didier L.): equivalent of the <column>_will_change! ActiveModel method
          begin
            value = __send__(column)
            value = value.duplicable? ? value.clone : value
          rescue TypeError, NoMethodError
          end
          setup_modifications
          @modifications[column] = value

          super
        end

        def #{column}_changed?
          column = _mounter(:#{column}).serialization_column
          send(:"\#{column}_changed?")
        end
      RUBY

    end
  end # Mongoid
end # CarrierWave

Mongoid::Document::ClassMethods.send(:include, CarrierWave::Mongoid)
