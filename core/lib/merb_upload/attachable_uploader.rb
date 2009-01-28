module Merb
  module Upload
    
    class AttachableUploader < Uploader
    
      attr_reader :model
      
      def initialize(model, identifier)
        @model = model
        @identifier = identifier
      end
      
    end
    
  end
end