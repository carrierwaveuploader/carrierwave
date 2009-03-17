require 'dm-core'

module CarrierWave
  module DataMapper

    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader)
      super

      alias_method :read_uploader, :attribute_get
      alias_method :write_uploader, :attribute_set

      before :save do
        send("store_#{column}!")
      end
    end

  end # DataMapper
end # CarrierWave

DataMapper::Model.send(:include, CarrierWave::DataMapper)
