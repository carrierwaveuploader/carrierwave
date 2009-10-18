# encoding: utf-8

module Merb
  module Generators
    class UploaderGenerator < NamedGenerator

      def self.source_root
        File.join(File.dirname(__FILE__), '..', '..', 'rails_generators', 'uploader', 'templates')
      end

      first_argument :name, :required => true, :desc => "The name of this uploader"

      template :uploader do |t|
        t.source = 'uploader.rb'
        t.destination = "app/uploaders/#{file_name}_uploader.rb"
      end
    end

    add :uploader, UploaderGenerator

  end
end
