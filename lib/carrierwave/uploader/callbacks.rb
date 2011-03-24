# encoding: utf-8

module CarrierWave
  module Uploader
    module Callbacks

      setup do
        extlib_inheritable_accessor :_before_callbacks, :_after_callbacks
      end

      def with_callbacks(kind, *args)
        self.class._before_callbacks[kind].each { |callback| self.send(callback, *args) }
        yield
        self.class._after_callbacks[kind].each { |callback| self.send(callback, *args) }
      end

      module ClassMethods

        def before(kind, callback)
          self._before_callbacks ||= Hash.new []
	  self._before_callbacks[kind] += [callback]
        end

        def after(kind, callback)
          self._after_callbacks ||= Hash.new []
	  self._after_callbacks[kind] += [callback]
        end
      end # ClassMethods

    end # Callbacks
  end # Uploader
end # CarrierWave