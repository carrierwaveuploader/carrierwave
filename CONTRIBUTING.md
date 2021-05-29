# Contributing to CarrierWave

CarrierWave thrives on a large number of [contributors](https://github.com/carrierwaveuploader/carrierwave/contributors),
and pull requests are very welcome. Before submitting a pull request, please make sure that your changes are well tested.

First, make sure you have `imagemagick` and `ghostscript` installed. You may need `libmagic` as well.

Then, you'll need to install bundler and the gem dependencies:

  `gem install bundler && bundle install`

You should now be able to run the local tests:

  `bundle exec rake`

You can also run the remote specs by creating a ~/.fog file:

```yaml
:carrierwave:
  :aws_access_key_id: xxx
  :aws_secret_access_key: yyy
  :rackspace_username: xxx
  :rackspace_api_key: yyy
  :google_storage_access_key_id: xxx
  :google_storage_secret_access_key: yyy
```

You should now be able to run the remote tests:

    REMOTE=true bundle exec rake

Please test with the latest Ruby 2.2.x version using RVM if possible.
