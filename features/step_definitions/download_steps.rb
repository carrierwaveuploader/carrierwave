When /^I download the file '([^']+)'/ do |url|
  unless ENV['REMOTE'] == 'true'
    sham_rack_app = ShamRack.at('s3.amazonaws.com').stub
    sham_rack_app.register_resource('/Monkey/testfile.txt', 'S3 Remote File', 'text/plain')
  end

  @uploader.download!(url)

  unless ENV['REMOTE'] == 'true'
    ShamRack.unmount_all
  end
end
