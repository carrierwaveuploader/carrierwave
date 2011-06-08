# encoding: utf-8

require 'mongoid'
require 'mongoid/dirty'
require 'carrierwave/validations/active_model'

module Mongoid #:nodoc:
  module Dirty #:nodoc:
    def attribute_will_change!(name) #:nodoc:
      begin
        value = __send__(name)
        value = value.duplicable? ? value.clone : value
      rescue TypeError, NoMethodError
      end

      @modifications[name] = value
    end

    module ClassMethods #:nodoc:
      def add_dirty_methods_with_will_change(name)
        add_dirty_methods_without_will_change(name)
        define_method("#{name}_will_change!") { attribute_will_change!(name) } unless instance_methods.include?("#{name}_will_change!") || instance_methods.include?(:"#{name}_will_change!")
      end

      alias_method_chain :add_dirty_methods, :will_change
    end
  end
end

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
          send(:"\#{column}_will_change!")
          super
        end
      RUBY

    end
  end # Mongoid
end # CarrierWave

Mongoid::Document::ClassMethods.send(:include, CarrierWave::Mongoid)
