# encoding: utf-8

When /^I assign the file '([^\']*)' to the '([^\']*)' column$/ do |path, column|
  @instance.send("#{column}=", File.open(file_path(path)))
end

Given /^the uploader class is mounted on the '([^\']*)' column$/ do |column|
  @mountee_klass.mount_uploader column.to_sym, @klass
end

When /^I retrieve the file later from the cache name for the column '([^\']*)'$/ do |column|
  new_instance = @instance.class.new
  new_instance.send("#{column}_cache=", @instance.send("#{column}_cache"))
  @instance = new_instance
end

Then /^the url for the column '([^\']*)' should be '([^\']*)'$/ do |column, url|
  @instance.send("#{column}_url").should == url
end
