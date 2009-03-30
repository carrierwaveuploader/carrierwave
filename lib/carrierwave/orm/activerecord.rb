require 'activerecord'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount
    
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute

      before_save do |record|
        record.send("store_#{column}!")
      end
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.send(:extend, CarrierWave::ActiveRecord)
