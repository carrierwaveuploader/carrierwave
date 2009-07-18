# encoding: utf-8

class UploaderGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      m.directory 'app/uploaders'
      m.template  'uploader.rb', "app/uploaders/#{name.underscore}_uploader.rb"
    end
  end

  def class_name
    name.camelize
  end

  protected

  def banner
    "Usage: #{$0} uploader UploaderName"
  end
end
