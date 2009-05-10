module CarrierWave
  module Uploader
    module Callbacks

      def self.append_features(base)
        super
        base.send(:include, ActiveSupport::NewCallbacks)
        base.define_callbacks :cache, :store, :remove
      end # ClassMethods

    end # Url
  end # Uploader
end # CarrierWave