# encoding: utf-8

Given /^the file '(.*?)' is cached file at '(.*?)'$/ do |file, cached|
  FileUtils.mkdir_p(File.dirname(file_path(cached)))
  FileUtils.cp(file_path(file), file_path(cached))
end

When /^I cache the file '(.*?)'$/ do |file|
  @uploader.cache!(File.open(file_path(file)))
end

When /^I retrieve the cache name '(.*?)' from the cache$/ do |name|
  @uploader.retrieve_from_cache!(name)
end