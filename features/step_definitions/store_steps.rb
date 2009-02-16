When /^I store the file$/ do
  @uploader.store!
end

When /^I store the file '(.*?)'$/ do |file|
  @uploader.store!(File.open(file_path(file)))
end