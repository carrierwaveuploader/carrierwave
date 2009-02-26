require 'activerecord'

module Stapler
    module ActiveRecord

      include Stapler::Mount

      def after_mount(column, uploader)
        alias_method :read_uploader, :read_attribute
        alias_method :write_uploader, :write_attribute

        before_save do |record|
          record.send("store_#{column}!")
        end
      end

    end # ActiveRecord
end # Stapler

ActiveRecord::Base.send(:extend, Stapler::ActiveRecord)