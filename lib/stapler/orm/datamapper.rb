require 'dm-core'

module Stapler
    module DataMapper

      include Stapler::Mount

      def after_mount(column, uploader)
        alias_method :read_uploader, :attribute_get
        alias_method :write_uploader, :attribute_set

        include Stapler::DataMapper::Extension

        before :save do
          send("store_#{column}!")
        end
      end

    end # DataMapper
end # Stapler

DataMapper::Model.send(:include, Stapler::DataMapper)