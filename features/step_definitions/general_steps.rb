# encoding: utf-8

Given /^an uploader class that uses the '(.*?)' storage$/ do |kind|
  @klass = Class.new(CarrierWave::Uploader::Base)
  @klass.storage = kind.to_sym
end

Given /^an instance of that class$/ do
  @uploader = @klass.new
end

Then /^the contents of the file should be '(.*?)'$/ do |contents|
  @uploader.read.chomp.should == contents
end

Given /^that the uploader reverses the filename$/ do
  @klass.class_eval do
    def filename
      super.reverse unless super.blank?
    end
  end
end

Given /^that the uploader has the filename overridden to '(.*?)'$/ do |filename|
  @klass.class_eval do
    define_method(:filename) do
      filename
    end
  end
end

Given /^that the uploader has the store_dir overridden to '(.*?)'$/ do |store_dir|
  @klass.class_eval do
    define_method(:store_dir) do
      file_path(store_dir)
    end
  end
end

Given /^that the version '(.*?)' has the store_dir overridden to '(.*?)'$/ do |version, store_dir|
  @klass.versions[version.to_sym].class_eval do
    define_method(:store_dir) do
      file_path(store_dir)
    end
  end
end

Given /^that the uploader class has a version named '(.*?)'$/ do |name|
  @klass.version(name)
end

Given /^yo dawg, I put a version called '(.*?)' in your version called '(.*?)'$/ do |v2, v1|
  @klass.version(v1) do
    version(v2)
  end
end

Given /^the class has a method called 'reverse' that reverses the contents of a file$/ do
  @klass.class_eval do
    def reverse
      text = File.read(current_path)
      File.open(current_path, 'w') { |f| f.write(text.reverse) }
    end
  end
end

Given /^the class will process '([a-zA-Z0-9\_\?!]*)'$/ do |name|
  @klass.process name.to_sym
end

Then /^the uploader should have '(.*?)' as its current path$/ do |path|
  @uploader.current_path.should == file_path(path)
end

Then /^the uploader should have the url '(.*?)'$/ do |url|
  @uploader.url.should == url
end

Then /^the uploader's version '(.*?)' should have the url '(.*?)'$/ do |version, url|
  @uploader.versions[version.to_sym].url.should == url
end

Then /^the uploader's nested version '(.*?)' nested in '(.*?)' should have the url '(.*?)'$/ do |v2, v1, url|
  @uploader.versions[v1.to_sym].versions[v2.to_sym].url.should == url
end