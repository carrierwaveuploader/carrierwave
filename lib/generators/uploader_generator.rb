require 'rails/generators'
require 'rails/generators/named_base'

class UploaderGenerator < Rails::Generators::NamedBase
  def create_uploader_file
    template 'uploader.rb', File.join('app/uploaders', class_path, "#{file_name}.rb")
  end
end

