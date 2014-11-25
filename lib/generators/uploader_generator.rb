class UploaderGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def create_uploader_file
    template "uploader.rb", File.join('app/uploaders', class_path, "#{uploader_file_name}_uploader.rb")
  end

  def uploader_file_name
    file_name.gsub("_uploader", "")
  end

  def uploader_class_name
    class_name.gsub("Uploader", "")
  end
end
