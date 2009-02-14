require 'dm-core'

module Merb
  module Upload
    module DataMapper

      include Merb::Upload::Mount

      module Extension

        def read_uploader(column)
          attribute_get(column)
        end

        def write_uploader(column, identifier)
          attribute_set(column, identifier)
        end

      end

      def after_mount(column, uploader)

        include Merb::Upload::DataMapper::Extension

        before :save do
          store_uploader(column)
        end
      end

    end # DataMapper
  end # Upload
end # Merb