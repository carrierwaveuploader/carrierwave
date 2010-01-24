When /^I download the file '([^']+)'/ do |url|
  @uploader.download!(url)
end

