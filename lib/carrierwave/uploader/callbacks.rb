module CarrierWave
  module Uploader
    module Callbacks

      setup do
        extlib_inheritable_accessor :_before_callbacks, :_after_callbacks
      end

      def with_callbacks(kind, *args)
        self.class._before_callback(kind).each { |callback| self.send(callback, *args) }
        yield
        self.class._after_callback(kind).each { |callback| self.send(callback, *args) }
      end

      module ClassMethods
        
        def _before_callback(kind) #:nodoc:
          self._before_callbacks ||= {}
          self._before_callbacks[kind] ||= []
          self._before_callbacks[kind]
        end

        def _after_callback(kind) #:nodoc:
          self._after_callbacks ||= {}
          self._after_callbacks[kind] ||= []
          self._after_callbacks[kind]
        end

        def before(kind, callback)
          _before_callback(kind) << callback
        end

        def after(kind, callback)
          _after_callback(kind) << callback
        end
      end # ClassMethods

    end # Callbacks
  end # Uploader
end # CarrierWave