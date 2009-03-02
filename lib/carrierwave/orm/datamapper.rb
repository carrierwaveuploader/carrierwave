require 'dm-core'

module CarrierWave
  module DataMapper

    include CarrierWave::Mount

    def after_mount(column, uploader)
      alias_method :read_uploader, :attribute_get
      alias_method :write_uploader, :attribute_set

      before :save do
        send("store_#{column}!")
      end
    end

  end # DataMapper
end # CarrierWave

DataMapper::Model.send(:include, CarrierWave::DataMapper)