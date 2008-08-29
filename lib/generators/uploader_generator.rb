module Merb
  module Generators
    class UploaderGenerator < NamedGenerator
      
      def self.source_root
        File.join(File.dirname(__FILE__), 'templates')
      end
      
      first_argument :name, :required => true, :desc => "The name of this uploader"
      
      template :uploader do
        source 'uploader.rbt'
        destination "app/uploaders/#{file_name}_uploader.rb"
      end
    end
    
    add :uploader, UploaderGenerator
    
  end
end