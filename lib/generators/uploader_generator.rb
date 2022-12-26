class UploaderGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def create_uploader_file
    template "uploader.rb.erb", File.join('app/uploaders', class_path, "#{file_name}_uploader.rb")
  end
end
