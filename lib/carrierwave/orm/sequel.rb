require 'sequel'
 
module CarrierWave
  module Sequel
    include CarrierWave::Mount
 
    def mount_uploader(column, uploader)
      super
 
      alias_method :read_uploader, :[]
      alias_method :write_uploader, :[]=
 
      if CarrierWave::Sequel.new_sequel?
        include CarrierWave::Sequel::Hooks
        include CarrierWave::Sequel::Validations
      else
        after_save "store_#{column}!"
        before_save "write_#{column}_identifier"
        before_destroy "remove_#{column}!"
      end
    end
 
    # Determine if we're using Sequel > 2.12
    #
    # ==== Returns
    # Bool:: True if Sequel 2.12 or higher False otherwise
    def self.new_sequel?
      ::Sequel::Model.respond_to?(:plugin)
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
