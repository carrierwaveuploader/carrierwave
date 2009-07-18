# encoding: utf-8

Given /^the file '(.*?)' is stored at '(.*?)'$/ do |file, stored|
  FileUtils.mkdir_p(File.dirname(file_path(stored)))
  FileUtils.cp(file_path(file), file_path(stored))
end

When /^I store the file$/ do
  @uploader.store!
end

When /^I store the file '(.*?)'$/ do |file|
  @uploader.store!(File.open(file_path(file)))
end

When /^I retrieve the file '(.*?)' from the store$/ do |identifier|
  @uploader.retrieve_from_store!(identifier)
end
