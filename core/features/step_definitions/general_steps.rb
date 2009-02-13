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
      Merb.root / store_dir
    end
  end
end

Then /^there should be a file at '(.*?)'$/ do |file|
  File.exist?(file_path(file)).should be_true
end

Then /^there should not be a file at '(.*?)'$/ do |file|
  File.exist?(file_path(file)).should be_false
end

Then /^the file at '(.*?)' should be identical to the file at '(.*?)'$/ do |one, two|
  File.read(file_path(one)).should == File.read(file_path(two))
end

Then /^there should be a file called '(.*?)' somewhere in a subdirectory of '(.*?)'$/ do |file, directory|
  Dir.glob(File.join(file_path(directory), '**', file)).any?.should be_true
end

Then /^the file called '(.*?)' in a subdirectory of '(.*?)' should be identical to the file at '(.*?)'$/ do |file, directory, other|
  File.read(Dir.glob(File.join(file_path(directory), '**', file)).first).should == File.read(file_path(other))
end

Then /^the uploader should have '(.*?)' as its current path$/ do |path|
  @uploader.current_path.should == file_path(path)
end