require 'activerecord'

module Merb
  module Upload
    module ActiveRecord

      include Merb::Upload::Mount

      def after_mount(column, uploader)
        alias_method :read_uploader, :read_attribute
        alias_method :write_uploader, :write_attribute

        before_save do |record|
          record.send("store_#{column}!")
        end
        
        before_validation do |record|
          record.send("set_#{column}_column")
        end
      end

    end # ActiveRecord
  end # Upload
end # Merb

ActiveRecord::Base.send(:extend, Merb::Upload::ActiveRecord)