require 'rails/generators'
require 'rails/generators/named_base'

class UploaderGenerator < Rails::Generators::NamedBase
  def create_uploader_file
    template 'uploader.rb', File.join('app/uploaders', class_path, "#{file_name}.rb")
  end
  
  def self.source_root
    @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
  end
end

