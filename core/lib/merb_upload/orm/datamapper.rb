require 'dm-core'

module Merb
  module Upload
    module DataMapper

      include Merb::Upload::Mount

      def after_mount(column, uploader)
        alias_method :read_uploader, :attribute_get
        alias_method :write_uploader, :attribute_set

        include Merb::Upload::DataMapper::Extension

        before :save do
          send("store_#{column}!")
        end
      end

    end # DataMapper
  end # Upload
end # Merb