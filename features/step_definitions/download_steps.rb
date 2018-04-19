When /^I download the file '([^']+)'/ do |url|
  unless ENV['REMOTE'] == 'true'
    stub_request(:get, "s3.amazonaws.com/Monkey/testfile.txt").
      to_return(body: "S3 Remote File", headers: { "Content-Type" => "text/plain" })
  end

  @uploader.download!(url)
end
