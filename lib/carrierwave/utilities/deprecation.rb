# encoding: utf-8
require 'active_support/deprecation'

module CarrierWave
  module Utilities
    module Deprecation

      def self.new version = '0.11.0', message = 'Carrierwave'
        if ActiveSupport::VERSION::MAJOR < 4
          ActiveSupport::Deprecation.warn("#{message} (will be removed from version #{version})")
        else
          ActiveSupport::Deprecation.new(version, message)
        end
      end

    end # Deprecation
  end # Utilities
end # CarrierWave
