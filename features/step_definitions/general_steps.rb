Given /^an uploader class that uses the 'file' storage$/ do
  @klass = Class.new(Merb::Upload::Uploader)
end

Given /^an instance of that class$/ do
  @uploader = @klass.new
end

Given /^that the uploader reverses the filename$/ do
  @klass.class_eval do
    def filename
      super.reverse unless super.blank?
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
  @klass.version name.to_sym
end

Given /^the class has a method called 'reverse' that reverses the contents of a file$/ do
  @klass.class_eval do
    def reverse
      File.open(current_path, 'w') { |f| f.write File.read(current_path).reverse }
    end
  end
end

Given /^the class will process '([a-zA-Z0-9\_\?!]*)'$/ do |name|
  @klass.process name.to_sym
end

Then /^the uploader should have '(.*?)' as its current path$/ do |path|
  @uploader.current_path.should == file_path(path)
end