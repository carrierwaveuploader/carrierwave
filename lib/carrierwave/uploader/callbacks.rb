# encoding: utf-8

module CarrierWave
  module Uploader
    module Callbacks
      extend ActiveSupport::Concern

      configurables = :_before_callbacks, :_after_callbacks

      included do
        if respond_to?(:class_attribute)
          class_attribute *configurables, :instance_writer => false
        else
          class_inheritable_accessor *configurables
        end
      end

      def with_callbacks(kind, *args)
        self.class._before_callbacks_for(kind).each { |callback| self.send(callback, *args) }
        yield
        self.class._after_callbacks_for(kind).each { |callback| self.send(callback, *args) }
      end

      module ClassMethods
        
        def _before_callbacks_for(kind) #:nodoc:
          (self._before_callbacks || { kind => [] })[kind] || []
        end

        def _after_callbacks_for(kind) #:nodoc:
          (self._after_callbacks || { kind => [] })[kind] || []
        end

        def before(kind, callback)
          self._before_callbacks ||= {}
          self._before_callbacks[kind] = _before_callbacks_for(kind) + [callback]
        end

        def after(kind, callback)
          self._after_callbacks ||= {}
          self._after_callbacks[kind] = _after_callbacks_for(kind) + [callback]
        end
      end # ClassMethods

    end # Callbacks
  end # Uploader
end # CarrierWave
