module Merb
  module Uploader
    
    def self.included(base)
      super
      base.extend ClassMethods
    end
    
    
    module ClassMethods
      
      def upload!(identifier, file)
        self.new(identifier).upload(file)
      end
      
      def retrieve!(identifier)
        self.new(identifier)
      end
      
    end
    
  end
end