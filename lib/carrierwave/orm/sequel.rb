# encoding: utf-8

require 'sequel'
 
module CarrierWave
  module Sequel
    include CarrierWave::Mount
 
    def mount_uploader(column, uploader)
      super
 
      alias_method :read_uploader, :[]
      alias_method :write_uploader, :[]=
 
      include CarrierWave::Sequel::Hooks
      include CarrierWave::Sequel::Validations
    end
  end # Sequel
end # CarrierWave
 
# Instance hook methods for the Sequel 3.x
module CarrierWave::Sequel::Hooks
  def after_save
    return false if super == false
    self.class.uploaders.each_key {|column| self.send("store_#{column}!") }
  end

  def before_save
    return false if super == false
    self.class.uploaders.each_key {|column| self.send("write_#{column}_identifier") }
  end

  def before_destroy
    return false if super == false
    self.class.uploaders.each_key {|column| self.send("remove_#{column}!") }
  end
end

# Instance validation methods for the Sequel 3.x
module CarrierWave::Sequel::Validations
end

Sequel::Model.send(:extend, CarrierWave::Sequel)
