require 'sequel'

module CarrierWave
  module Sequel

    include CarrierWave::Mount

    def mount_uploader(column, uploader)
      super

      alias_method :read_uploader, :[]
      alias_method :write_uploader, :[]=

      before_save do
        send("store_#{column}!")
      end
    end

  end # Sequel
end # CarrierWave

Sequel::Model.send(:extend, CarrierWave::Sequel)

