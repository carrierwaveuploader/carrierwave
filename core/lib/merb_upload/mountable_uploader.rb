module Merb
  module Upload
    
    class MountableUploader < Uploader
    
      attr_reader :model, :mounted_as
      
      def initialize(model, mounted_as, identifier)
        @model = model
        @mounted_as = mounted_as
        @identifier = identifier
      end
      
    end
    
  end
end