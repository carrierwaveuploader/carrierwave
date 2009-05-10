module CarrierWave
  module Uploader
    module Callbacks

      def self.append_features(base)
        super
        base.send(:include, ActiveSupport::Callbacks)
        base.define_callbacks :before_cache, :after_cache
      end # ClassMethods

    end # Url
  end # Uploader
end # CarrierWave