# encoding: utf-8
require 'mongo_mapper'

module CarrierWave
  module MongoMapper
    include CarrierWave::Mount
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      # We need to set the mount_on column (or key in MongoMapper's case)
      # since MongoMapper will attempt to set the filename on 
      # the uploader instead of the file on a Document's initialization.
      options[:mount_on] ||= "#{column}_filename"
      key options[:mount_on]
      
      super
      alias_method :read_uploader, :[]
      alias_method :write_uploader, :[]=
      after_save "store_#{column}!".to_sym
      before_save "write_#{column}_identifier".to_sym
      after_destroy "remove_#{column}!".to_sym
    end
  end # MongoMapper
end # CarrierWave

MongoMapper::Document::ClassMethods.send(:include, CarrierWave::MongoMapper)
