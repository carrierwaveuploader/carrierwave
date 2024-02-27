# CarrierWave

This gem provides a simple and extremely flexible way to upload files from Ruby applications.
It works well with Rack based web applications, such as Ruby on Rails.

[![Build Status](https://github.com/carrierwaveuploader/carrierwave/workflows/Test/badge.svg)](https://github.com/carrierwaveuploader/carrierwave/actions)
[![Code Climate](https://codeclimate.com/github/carrierwaveuploader/carrierwave.svg)](https://codeclimate.com/github/carrierwaveuploader/carrierwave)
[![SemVer](https://api.dependabot.com/badges/compatibility_score?dependency-name=carrierwave&package-manager=bundler&version-scheme=semver)](https://dependabot.com/compatibility-score.html?dependency-name=carrierwave&package-manager=bundler&version-scheme=semver)


## Information

* RDoc documentation [available on RubyDoc.info](https://rubydoc.info/gems/carrierwave)
* Source code [available on GitHub](http://github.com/carrierwaveuploader/carrierwave)
* More information, known limitations, and how-tos [available on the wiki](https://github.com/carrierwaveuploader/carrierwave/wiki)

## Getting Help

* Please ask the community on [Stack Overflow](https://stackoverflow.com/questions/tagged/carrierwave) for help if you have any questions. Please do not post usage questions on the issue tracker.
* Please report bugs on the [issue tracker](http://github.com/carrierwaveuploader/carrierwave/issues) but read the "getting help" section in the wiki first.

## Installation

Install the latest release:

```
$ gem install carrierwave
```

In Rails, add it to your Gemfile:

```ruby
gem 'carrierwave', '~> 3.0'
```

Finally, restart the server to apply the changes.

## Upgrading from 2.x or earlier

CarrierWave 3.0 comes with a change in the way of handling the file extension on conversion. This results in following issues if you use `process convert: :format` to change the file format:

- If you have it on the uploader itself (not within a version), the file extension of the cached file will change. That means if you serve both CarrierWave 2.x and 3.x simultaneously on the same workload (e.g. using blue-green deployment), a cache file stored by 2.x can't be retrieved by 3.x and vice versa.
- If you have it within a version, the file extension of the stored file will change. You need to perform `#recreate_versions!` to make it usable again.

To preserve the 2.x behavior, you can set `force_extension false` right after calling `process convert: :format`. See [#2659](https://github.com/carrierwaveuploader/carrierwave/pull/2659) for the detail.

## Getting Started

Start off by generating an uploader:

	rails generate uploader Avatar

this should give you a file in:

	app/uploaders/avatar_uploader.rb

Check out this file for some hints on how you can customize your uploader. It
should look something like this:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :file
end
```

You can use your uploader class to store and retrieve files like this:

```ruby
uploader = AvatarUploader.new

uploader.store!(my_file)

uploader.retrieve_from_store!('my_file.png')
```

CarrierWave gives you a `store` for permanent storage, and a `cache` for
temporary storage. You can use different stores, including filesystem
and cloud storage.

Most of the time you are going to want to use CarrierWave together with an ORM.
It is quite simple to mount uploaders on columns in your model, so you can
simply assign files and get going:

### ActiveRecord

Make sure you are loading CarrierWave after loading your ORM, otherwise you'll
need to require the relevant extension manually, e.g.:

```ruby
require 'carrierwave/orm/activerecord'
```

Add a string column to the model you want to mount the uploader by creating
a migration:


	rails g migration add_avatar_to_users avatar:string
	rails db:migrate

Open your model file and mount the uploader:

```ruby
class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
end
```

Now you can cache files by assigning them to the attribute, they will
automatically be stored when the record is saved.

```ruby
u = User.new
u.avatar = params[:file] # Assign a file like this, or

# like this
File.open('somewhere') do |f|
  u.avatar = f
end

u.save!
u.avatar.url # => '/url/to/file.png'
u.avatar.current_path # => 'path/to/file.png'
u.avatar_identifier # => 'file.png'
```

**Note**: `u.avatar` will never return nil, even if there is no photo associated to it.
To check if a photo was saved to the model, use `u.avatar.file.nil?` instead.

### DataMapper, Mongoid, Sequel

Other ORM support has been extracted into separate gems:

* [carrierwave-datamapper](https://github.com/carrierwaveuploader/carrierwave-datamapper)
* [carrierwave-mongoid](https://github.com/carrierwaveuploader/carrierwave-mongoid)
* [carrierwave-sequel](https://github.com/carrierwaveuploader/carrierwave-sequel)

There are more extensions listed in [the wiki](https://github.com/carrierwaveuploader/carrierwave/wiki)

## Multiple file uploads

CarrierWave also has convenient support for multiple file upload fields.

### ActiveRecord

Add a column which can store an array. This could be an array column or a JSON
column for example. Your choice depends on what your database supports. For
example, create a migration like this:


#### For databases with ActiveRecord json data type support (e.g. PostgreSQL, MySQL)

	rails g migration add_avatars_to_users avatars:json
	rails db:migrate

#### For database without ActiveRecord json data type support (e.g. SQLite)

	rails g migration add_avatars_to_users avatars:string
	rails db:migrate

__Note__: JSON datatype doesn't exists in SQLite adapter, that's why you can use a string datatype which will be serialized in model.

Open your model file and mount the uploader:


```ruby
class User < ApplicationRecord
  mount_uploaders :avatars, AvatarUploader
  serialize :avatars, JSON # If you use SQLite, add this line.
end
```

Make sure that you mount the uploader with write (mount_uploaders) with `s` not (mount_uploader)
in order to avoid errors when uploading multiple files

Make sure your file input fields are set up as multiple file fields. For
example in Rails you'll want to do something like this:

```erb
<%= form.file_field :avatars, multiple: true %>
```

Also, make sure your upload controller permits the multiple file upload attribute, *pointing to an empty array in a hash*. For example:

```ruby
params.require(:user).permit(:email, :first_name, :last_name, {avatars: []})
```

Now you can select multiple files in the upload dialog (e.g. SHIFT+SELECT), and they will
automatically be stored when the record is saved.

```ruby
u = User.new(params[:user])
u.save!
u.avatars[0].url # => '/url/to/file.png'
u.avatars[0].current_path # => 'path/to/file.png'
u.avatars[0].identifier # => 'file.png'
```

If you want to preserve existing files on uploading new one, you can go like:

```erb
<% user.avatars.each do |avatar| %>
  <%= hidden_field :user, :avatars, multiple: true, value: avatar.identifier %>
<% end %>
<%= form.file_field :avatars, multiple: true %>
```

Sorting avatars is supported as well by reordering `hidden_field`, an example using jQuery UI Sortable is available [here](https://github.com/carrierwaveuploader/carrierwave/wiki/How-to%3A-Add%2C-remove-and-reorder-images-using-multiple-file-upload).

## Changing the storage directory

In order to change where uploaded files are put, just override the `store_dir`
method:

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def store_dir
    'public/my/upload/directory'
  end
end
```

This works for the file storage as well as Amazon S3 and Rackspace Cloud Files.
Define `store_dir` as `nil` if you'd like to store files at the root level.

If you store files outside the project root folder, you may want to define `cache_dir` in the same way:

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def cache_dir
    '/tmp/projectname-cache'
  end
end
```

## Changing the filename

To change the filename of uploaded files, you can override `#filename` method in the uploader.

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def filename
    "image.#{file.extension}" # If you upload 'file.jpg', you'll get 'image.jpg'
  end
end
```

Some old documentations (like [this](https://stackoverflow.com/a/5865117)) may instruct you to safeguard the filename value with `if original_filename`, but it's no longer necessary with CarrierWave 3.0 or later.

## Securing uploads

Certain files might be dangerous if uploaded to the wrong location, such as PHP
files or other script files. CarrierWave allows you to specify an allowlist of
allowed extensions or content types.

If you're mounting the uploader, uploading a file with the wrong extension will
make the record invalid instead. Otherwise, an error is raised.

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def extension_allowlist
    %w(jpg jpeg gif png)
  end
end
```

The same thing could be done using content types.
Let's say we need an uploader that accepts only images. This can be done like this

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def content_type_allowlist
    /image\//
  end
end
```

You can use a denylist to reject content types.
Let's say we need an uploader that reject JSON files. This can be done like this

```ruby
class NoJsonUploader < CarrierWave::Uploader::Base
  def content_type_denylist
    ['application/text', 'application/json']
  end
end
```

### CVE-2016-3714 (ImageTragick)
This version of CarrierWave has the ability to mitigate CVE-2016-3714. However, you **MUST** set a content_type_allowlist in your uploaders for this protection to be effective, and you **MUST** either disable ImageMagick's default SVG delegate or use the RSVG delegate for SVG processing.


A valid allowlist that will restrict your uploader to images only, and mitigate the CVE is:

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def content_type_allowlist
    [/image\//]
  end
end
```

**WARNING**: A `content_type_allowlist` is the only form of allowlist or denylist supported by CarrierWave that can effectively mitigate against CVE-2016-3714. Use of `extension_allowlist` will not inspect the file headers, and thus still leaves your application open to the vulnerability.

### Filenames and unicode chars

Another security issue you should care for is the file names (see
[Ruby On Rails Security Guide](http://guides.rubyonrails.org/security.html#file-uploads)).
By default, CarrierWave provides only English letters, arabic numerals and some symbols as
allowlisted characters in the file name. If you want to support local scripts (Cyrillic letters, letters with diacritics and so on), you
have to override `sanitize_regexp` method. It should return regular expression which would match
all *non*-allowed symbols.

```ruby
CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
```

Also make sure that allowing non-latin characters won't cause a compatibility issue with a third-party
plugins or client-side software.

## Setting the content type

As of v0.11.0, the `mime-types` gem is a runtime dependency and the content type is set automatically.
You no longer need to do this manually.

## Adding versions

Often you'll want to add different versions of the same file. The classic example is generating image thumbnails while preserving the original file to be used for high-quality representation.
In this section we'll explore how CarrierWave supports working with multiple versions. The image manipulation itself is covered in [another section](#manipulating-images).

```ruby
class MyUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  process resize_to_fit: [800, 800]

  version :thumb do
    process resize_to_fill: [200,200]
  end

end
```

When this uploader is used, an uploaded image would be scaled to be no larger
than 800 by 800 pixels. The original aspect ratio will be kept.

A version called `:thumb` is then created, which is scaled
to exactly 200 by 200 pixels. The thumbnail uses `resize_to_fill` which makes sure
that the width and height specified are filled, only cropping
if the aspect ratio requires it.

The above uploader could be used like this:

```ruby
uploader = AvatarUploader.new
uploader.store!(my_file)                              # size: 1024x768

uploader.url # => '/url/to/my_file.png'               # size: 800x800
uploader.thumb.url # => '/url/to/thumb_my_file.png'   # size: 200x200
```

One important thing to remember is that process is called *before* versions are
created. This can cut down on processing cost.

### Conditional processing

If you want to use conditional process, you can only use `if` statement.

See `carrierwave/uploader/processing.rb` for details.

```ruby
class MyUploader < CarrierWave::Uploader::Base
  process :scale => [200, 200], :if => :image?
  
  def image?(carrier_wave_sanitized_file)
    true
  end
end
```

### Nested versions

It is possible to nest versions within versions:

```ruby
class MyUploader < CarrierWave::Uploader::Base

  version :animal do
    version :human
    version :monkey
    version :llama
  end
end
```

### Conditional versions

Occasionally you want to restrict the creation of versions on certain
properties within the model or based on the picture itself.

```ruby
class MyUploader < CarrierWave::Uploader::Base

  version :human, if: :is_human?
  version :monkey, if: :is_monkey?
  version :banner, if: :is_landscape?

private

  def is_human? picture
    model.can_program?(:ruby)
  end

  def is_monkey? picture
    model.favorite_food == 'banana'
  end

  def is_landscape? picture
    image = MiniMagick::Image.new(picture.path)
    image[:width] > image[:height]
  end

end
```

The `model` variable points to the instance object the uploader is attached to.

### Create versions from existing versions

For performance reasons, it is often useful to create versions from existing ones
instead of using the original file. If your uploader generates several versions
where the next is smaller than the last, it will take less time to generate from
a smaller, already processed image.

```ruby
class MyUploader < CarrierWave::Uploader::Base

  version :thumb do
    process resize_to_fill: [280, 280]
  end

  version :small_thumb, from_version: :thumb do
    process resize_to_fill: [20, 20]
  end

end
```

### Customizing version filenames

CarrierWave supports [customization of filename](#changing-the-filename) by overriding an uploader's
#filename method, but this doesn't work for versions because of the limitation on how CarrierWave
re-constructs the filename on retrieval of the stored file.
Instead, you can override `#full_filename` with providing a version-aware name.

```ruby
class MyUploader < CarrierWave::Uploader::Base
  version :thumb do
    def full_filename(for_file)
      'thumb.png'
    end
    process convert: 'png'
  end
end
```

Please note that `#full_filename` mustn't be constructed based on a dynamic value
that can change from the time of store and time of retrieval, since it will result in
being unable to retrieve a file previously stored.

## Making uploads work across form redisplays

Often you'll notice that uploaded files disappear when a validation fails.
CarrierWave has a feature that makes it easy to remember the uploaded file even
in that case. Suppose your `user` model has an uploader mounted on `avatar`
file, just add a hidden field called `avatar_cache` (don't forget to add it to
the attr_accessible list as necessary). In Rails, this would look like this:

```erb
<%= form_for @user, html: { multipart: true } do |f| %>
  <p>
    <label>My Avatar</label>
    <%= f.file_field :avatar %>
    <%= f.hidden_field :avatar_cache %>
  </p>
<% end %>
````

It might be a good idea to show the user that a file has been uploaded, in the
case of images, a small thumbnail would be a good indicator:

```erb
<%= form_for @user, html: { multipart: true } do |f| %>
  <p>
    <label>My Avatar</label>
    <%= image_tag(@user.avatar_url) if @user.avatar? %>
    <%= f.file_field :avatar %>
    <%= f.hidden_field :avatar_cache %>
  </p>
<% end %>
```

## Removing uploaded files

If you want to remove a previously uploaded file on a mounted uploader, you can
easily add a checkbox to the form which will remove the file when checked.

```erb
<%= form_for @user, html: { multipart: true } do |f| %>
  <p>
    <label>My Avatar</label>
    <%= image_tag(@user.avatar_url) if @user.avatar? %>
    <%= f.file_field :avatar %>
  </p>

  <p>
    <label>
      <%= f.check_box :remove_avatar %>
      Remove avatar
    </label>
  </p>
<% end %>
```

If you want to remove the file manually, you can call <code>remove_avatar!</code>, then save the object.

```erb
@user.remove_avatar!
@user.save
#=> true
```

## Uploading files from a remote location

Your users may find it convenient to upload a file from a location on the Internet
via a URL. CarrierWave makes this simple, just add the appropriate attribute to your
form and you're good to go:

```erb
<%= form_for @user, html: { multipart: true } do |f| %>
  <p>
    <label>My Avatar URL:</label>
    <%= image_tag(@user.avatar_url) if @user.avatar? %>
    <%= f.text_field :remote_avatar_url %>
  </p>
<% end %>
```

If you're using ActiveRecord, CarrierWave will indicate invalid URLs and download
failures automatically with attribute validation errors. If you aren't, or you
disable CarrierWave's `validate_download` option, you'll need to handle those
errors yourself.

### Retry option for download from remote location
If you want to retry the download from the Remote URL, enable the download_retry_count option, an error occurs during download, it will try to execute the specified number of times.
This option is effective when the remote destination is unstable.

```rb
CarrierWave.configure do |config|
  config.download_retry_count = 3 # Default 0
  config.download_retry_wait_time = 3 # Default 5
end
```

## Providing a default URL

In many cases, especially when working with images, it might be a good idea to
provide a default url, a fallback in case no file has been uploaded. You can do
this easily by overriding the `default_url` method in your uploader:

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def default_url(*args)
    "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  end
end
```

Or if you are using the Rails asset pipeline:

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def default_url(*args)
    ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  end
end
```

## Recreating versions

You might come to a situation where you want to retroactively change a version
or add a new one. You can use the `recreate_versions!` method to recreate the
versions from the base file. This uses a naive approach which will re-upload and
process the specified version or all versions, if none is passed as an argument.

When you are generating random unique filenames you have to call `save!` on
the model after using `recreate_versions!`. This is necessary because
`recreate_versions!` doesn't save the new filename to the database. Calling
`save!` yourself will prevent that the database and file system are running
out of sync.

```ruby
instance = MyUploader.new
instance.recreate_versions!(:thumb, :large)
```

Or on a mounted uploader:

```ruby
User.find_each do |user|
  user.avatar.recreate_versions!
end
```

Note: `recreate_versions!` will throw an exception on records without an image. To avoid this, scope the records to those with images or check if an image exists within the block. If you're using ActiveRecord, recreating versions for a user avatar might look like this:

```ruby
User.find_each do |user|
  user.avatar.recreate_versions! if user.avatar?
end
```

## Configuring CarrierWave

CarrierWave has a broad range of configuration options, which you can configure,
both globally and on a per-uploader basis:

```ruby
CarrierWave.configure do |config|
  config.permissions = 0666
  config.directory_permissions = 0777
  config.storage = :file
end
```

Or alternatively:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  permissions 0777
end
```

If you're using Rails, create an initializer for this:

	config/initializers/carrierwave.rb

If you want CarrierWave to fail noisily in development, you can change these configs in your environment file:

```ruby
CarrierWave.configure do |config|
  config.ignore_integrity_errors = false
  config.ignore_processing_errors = false
  config.ignore_download_errors = false
end
```


## Testing with CarrierWave

It's a good idea to test your uploaders in isolation. In order to speed up your
tests, it's recommended to switch off processing in your tests, and to use the file storage.
Also, you can disable SSRF protection at your own risk using the `skip_ssrf_protection` configuration.

In Rails you could do that by adding an initializer with:

file storage. In Rails you could do that by adding an initializer with:

```ruby
if Rails.env.test? or Rails.env.cucumber?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
    config.skip_ssrf_protection = true
  end
end
```

Remember, if you have already set `storage :something` in your uploader, the `storage`
setting from this initializer will be ignored.

If you need to test your processing, you should test it in isolation, and enable
processing only for those tests that need it.

CarrierWave comes with some RSpec matchers which you may find useful:

```ruby
require 'carrierwave/test/matchers'

describe MyUploader do
  include CarrierWave::Test::Matchers

  let(:user) { double('user') }
  let(:uploader) { MyUploader.new(user, :avatar) }

  before do
    MyUploader.enable_processing = true
    File.open(path_to_file) { |f| uploader.store!(f) }
  end

  after do
    MyUploader.enable_processing = false
    uploader.remove!
  end

  context 'the thumb version' do
    it "scales down a landscape image to be exactly 64 by 64 pixels" do
      expect(uploader.thumb).to have_dimensions(64, 64)
    end
  end

  context 'the small version' do
    it "scales down a landscape image to fit within 200 by 200 pixels" do
      expect(uploader.small).to be_no_larger_than(200, 200)
    end
  end

  it "makes the image readable only to the owner and not executable" do
    expect(uploader).to have_permissions(0600)
  end

  it "has the correct format" do
    expect(uploader).to be_format('png')
  end
end
```

If you're looking for minitest asserts, checkout [carrierwave_asserts](https://github.com/hcfairbanks/carrierwave_asserts).

Setting the enable_processing flag on an uploader will prevent any of the versions from processing as well.
Processing can be enabled for a single version by setting the processing flag on the version like so:

```ruby
@uploader.thumb.enable_processing = true
```

## Fog

If you want to use fog you must add in your CarrierWave initializer the
following lines

```ruby
config.fog_credentials = { ... } # Provider specific credentials
```

## Using Amazon S3

[Fog AWS](http://github.com/fog/fog-aws) is used to support Amazon S3. Ensure you have it in your Gemfile:

```ruby
gem "fog-aws"
```

You'll need to provide your fog_credentials and a fog_directory (also known as a bucket) in an initializer.
For the sake of performance it is assumed that the directory already exists, so please create it if it needs to be.
You can also pass in additional options, as documented fully in lib/carrierwave/storage/fog.rb. Here's a full example:

```ruby
CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',                        # required
    aws_access_key_id:     'xxx',                        # required unless using use_iam_profile
    aws_secret_access_key: 'yyy',                        # required unless using use_iam_profile
    use_iam_profile:       true,                         # optional, defaults to false
    region:                'eu-west-1',                  # optional, defaults to 'us-east-1'
    host:                  's3.example.com',             # optional, defaults to nil
    endpoint:              'https://s3.example.com:8080' # optional, defaults to nil
  }
  config.fog_directory  = 'name_of_bucket'                                      # required
  config.fog_public     = false                                                 # optional, defaults to true
  config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" } # optional, defaults to {}
  # Use this if you have AWS S3 ACLs disabled.
  # config.fog_attributes = { 'x-amz-acl' => 'bucket-owner-full-control' }
  # Use this if you have Google Cloud Storage uniform bucket-level access enabled.
  # config.fog_attributes = { uniform: true }
  # For an application which utilizes multiple servers but does not need caches persisted across requests,
  # uncomment the line :file instead of the default :storage.  Otherwise, it will use AWS as the temp cache store.
  # config.cache_storage = :file
end
```

In your uploader, set the storage to :fog

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :fog
end
```

That's it! You can still use the `CarrierWave::Uploader#url` method to return the url to the file on Amazon S3.

**Note**: for Carrierwave to work properly it needs credentials with the following permissions:

* `s3:ListBucket`
* `s3:PutObject`
* `s3:GetObject`
* `s3:DeleteObject`
* `s3:PutObjectAcl`

## Using Rackspace Cloud Files

[Fog](http://github.com/fog/fog) is used to support Rackspace Cloud Files. Ensure you have it in your Gemfile:

```ruby
gem "fog"
```

You'll need to configure a directory (also known as a container), username and API key in the initializer.
For the sake of performance it is assumed that the directory already exists, so please create it if need be.

Using a US-based account:

```ruby
CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:           'Rackspace',
    rackspace_username: 'xxxxxx',
    rackspace_api_key:  'yyyyyy',
    rackspace_region:   :ord                      # optional, defaults to :dfw
  }
  config.fog_directory = 'name_of_directory'
end
```

Using a UK-based account:

```ruby
CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:           'Rackspace',
    rackspace_username: 'xxxxxx',
    rackspace_api_key:  'yyyyyy',
    rackspace_auth_url: Fog::Rackspace::UK_AUTH_ENDPOINT,
    rackspace_region:   :lon
  }
  config.fog_directory = 'name_of_directory'
end
```

You can optionally include your CDN host name in the configuration.
This is *highly* recommended, as without it every request requires a lookup
of this information.

```ruby
config.asset_host = "http://c000000.cdn.rackspacecloud.com"
```

In your uploader, set the storage to :fog

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :fog
end
```

That's it! You can still use the `CarrierWave::Uploader#url` method to return
the url to the file on Rackspace Cloud Files.

## Using Google Cloud Storage

[Fog](http://github.com/fog/fog-google) is used to support Google Cloud Storage. Ensure you have it in your Gemfile:

```ruby
gem "fog-google"
```

You'll need to configure a directory (also known as a bucket) and the credentials in the initializer.
For the sake of performance it is assumed that the directory already exists, so please create it if need be.

Please read the [fog-google README](https://github.com/fog/fog-google/blob/master/README.md) on how to get credentials.

For Google Storage JSON API (recommended):
```ruby
CarrierWave.configure do |config|
    config.fog_credentials = {
        provider:               'Google',
        google_project:         'my-project',
        google_json_key_string: 'xxxxxx'
        # or use google_json_key_location if using an actual file
    }
    config.fog_directory = 'google_cloud_storage_bucket_name'
end
```

For Google Storage XML API:
```ruby
CarrierWave.configure do |config|
    config.fog_credentials = {
        provider:                         'Google',
        google_storage_access_key_id:     'xxxxxx',
        google_storage_secret_access_key: 'yyyyyy'
    }
    config.fog_directory = 'google_cloud_storage_bucket_name'
end
```

In your uploader, set the storage to :fog

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :fog
end
```

That's it! You can still use the `CarrierWave::Uploader#url` method to return
the url to the file on Google.

## Optimized Loading of Fog

Since Carrierwave doesn't know which parts of Fog you intend to use, it will just load the entire library (unless you use e.g. [`fog-aws`, `fog-google`] instead of fog proper). If you prefer to load fewer classes into your application, you need to load those parts of Fog yourself *before* loading CarrierWave in your Gemfile.  Ex:

```ruby
gem "fog", "~> 1.27", require: "fog/rackspace/storage"
gem "carrierwave"
```

A couple of notes about versions:
* This functionality was introduced in Fog v1.20.
* This functionality is slated for CarrierWave v1.0.0.

If you're not relying on Gemfile entries alone and are requiring "carrierwave" anywhere, ensure you require "fog/rackspace/storage" before it.  Ex:

```ruby
require "fog/rackspace/storage"
require "carrierwave"
```

Beware that this specific require is only needed when working with a fog provider that was not extracted to its own gem yet.
A list of the extracted providers can be found in the page of the `fog` organizations [here](https://github.com/fog).

When in doubt, inspect `Fog.constants` to see what has been loaded.

## Dynamic Asset Host

The `asset_host` config property can be assigned a proc (or anything that responds to `call`) for generating the host dynamically. The proc-compliant object gets an instance of the current `CarrierWave::Storage::Fog::File` or `CarrierWave::SanitizedFile` as its only argument.

```ruby
CarrierWave.configure do |config|
  config.asset_host = proc do |file|
    identifier = # some logic
    "http://#{identifier}.cdn.rackspacecloud.com"
  end
end
```

## Manipulating images

If you're uploading images, you'll probably want to manipulate them in some way,
you might want to create thumbnail images for example.

### Using MiniMagick

MiniMagick performs all the operations using the 'convert' CLI which is part of the standard ImageMagick kit.
This allows you to have the power of ImageMagick without having to worry about installing
all the RMagick libraries, it often results in higher memory footprint.

See the MiniMagick site for more details:

https://github.com/minimagick/minimagick

To install Imagemagick on OSX with homebrew type the following:

```
$ brew install imagemagick
```

And the ImageMagick command line options for more for what's on offer:

http://www.imagemagick.org/script/command-line-options.php

Currently, the MiniMagick carrierwave processor provides exactly the same methods as
for the RMagick processor.

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  process resize_to_fill: [200, 200]
end
```

See `carrierwave/processing/mini_magick.rb` for details.

### Using RMagick

CarrierWave also comes with support for RMagick, a well-known image processing library.
To use it, you'll need to include this in your Uploader:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
end
```

The RMagick module gives you a few methods, like
`CarrierWave::RMagick#resize_to_fill` which manipulate the image file in some
way. You can set a `process` callback, which will call that method any time a
file is uploaded.
There is a demonstration of convert here.

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  process resize_to_fill: [200, 200]
  process convert: 'png'
end
```

Check out the manipulate! method, which makes it easy for you to write your own
manipulation methods.

### Using Vips

CarrierWave version 2.2.0 added support for the `libvips` image processing library, through [ImageProcessing::Vips](https://github.com/janko/image_processing/blob/master/doc/vips.md). Its functionality matches that of the RMagick and MiniMagick processors, but it uses less memory and offers [faster processing](https://github.com/libvips/libvips/wiki/Speed-and-memory-use). To use the Vips processing module you must first install `libvips`, for example: 

````bash
$ sudo apt install libvips
````

You also need to tell your uploader to use Vips:

````ruby
class ImageFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::Vips
end
````

### List of available processing methods:

> [!NOTE]
> While the intetion is to provide uniform interfaces to al three processing libraries the availability and implementation of processing methods can <a href="supported-processing-methods">vary slightly between them</a>.

- `convert` - Changes the image encoding format to the given format (eg. jpg). This operation is treated specially to trigger the change of the file extension, so it matches with the format of the resulting file.
- `resize_to_limit` - Resize the image to fit within the specified dimensions while retaining the original aspect ratio. Will only resize the image if it is larger than the specified dimensions. The resulting image may be shorter or narrower than specified in the smaller dimension but will not be larger than the specified values.
- `resize_to_fit` - Resize the image to fit within the specified dimensions while retaining the original aspect ratio. The image may be shorter or narrower than specified in the smaller dimension but will not be larger than the specified values.
- `resize_to_fill` - Resize the image to fit within the specified dimensions while retaining the aspect ratio of the original image. If necessary, crop the image in the larger dimension. Optionally, a "gravity" may be specified, for example "Center", or "NorthEast".
- `resize_and_pad` - Resize the image to fit within the specified dimensions while retaining the original aspect ratio. If necessary, will pad the remaining area with the given color, which defaults to transparent (for gif and png, white for jpeg). Optionally, a "gravity" may be specified, as above.
- `crop` - Crop the image to the contents of a box with the specified height and width, positioned a given number of pixels from the top and left. The original image edge will be retained should the bottom and/or right edge of the box fall outside the image bounds. 

#### Supported processing methods

The following table shows which processing methods are supported by each processing library, and which parameters they accept: 

Method|RMagick|MiniMagick|Vips
------|-----------------|-----------------|-----------------|
`convert`|`format`|`format`, `page`<sup>1</sup>|`format`, `page`<sup>1</sup>
`resize_to_limit`|`width`, `height`|`width`, `height`|`width`, `height`
`resize_to_fit`|`width`, `height`|`width`, `height`|`width`, `height`
`resize_to_fill`|`width`, `height`, `gravity`<sup>2</sup>|`width`, `height`, `gravity`<sup>2</sup>|`width`, `height`
`resize_and_pad`|`width`, `height`, `background`, `gravity`<sup>2</sup>|`width`, `height`, `background`, `gravity`<sup>2</sup>|`width`, `height`, `background`, `gravity`<sup>2</sup>
`resize_to_geometry_string`|`geometry_string`<sup>3</sup>|*not implemented*|*not implemented*
`crop`|`left`, `top`, `width`, `height`|`left`, `top`, `width`, `height`|`left`, `top`, `width`, `height`

<sup>1</sup>`page` refers to the page number when converting from PDF, frame number when converting from GIF, and layer number when converting from PSD.

<sup>2</sup>`gravity` refers to an image position given as one of `Center`, `North`, `NorthWest`, `West`, `SouthWest`, `South`, `SouthEast`, `East`, or `NorthEast`.

<sup>3</sup>`geometry_string` is an [ImageMagick geometry string](https://rmagick.github.io/imusage.html#geometry).

## Migrating from Paperclip

If you are using Paperclip, you can use the provided compatibility module:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::Compatibility::Paperclip
end
```

See the documentation for `CarrierWave::Compatibility::Paperclip` for more
details.

Be sure to use mount_on to specify the correct column:

```ruby
mount_uploader :avatar, AvatarUploader, mount_on: :avatar_file_name
```

## I18n

The Active Record validations use the Rails `i18n` framework. Add these keys to
your translations file:

```yaml
errors:
  messages:
    carrierwave_processing_error: failed to be processed
    carrierwave_integrity_error: is not of an allowed file type
    carrierwave_download_error: could not be downloaded
    extension_allowlist_error: "You are not allowed to upload %{extension} files, allowed types: %{allowed_types}"
    extension_denylist_error: "You are not allowed to upload %{extension} files, prohibited types: %{prohibited_types}"
    content_type_allowlist_error: "You are not allowed to upload %{content_type} files, allowed types: %{allowed_types}"
    content_type_denylist_error: "You are not allowed to upload %{content_type} files"
    processing_error: "Failed to manipulate, maybe it is not an image?"
    min_size_error: "File size should be greater than %{min_size}"
    max_size_error: "File size should be less than %{max_size}"
    min_width_error: "Image width should be greater than %{min_width}px"
    max_width_error: "Image width should be less than %{max_width}px"
    min_height_error: "Image height should be greater than %{min_height}px"
    max_height_error: "Image height should be less than %{max_height}px"
```

The [`carrierwave-i18n`](https://github.com/carrierwaveuploader/carrierwave-i18n)
library adds support for additional locales.

## Large files

By default, CarrierWave copies an uploaded file twice, first copying the file into the cache, then
copying the file into the store.  For large files, this can be prohibitively time consuming.

You may change this behavior by overriding either or both of the `move_to_cache` and
`move_to_store` methods:

```ruby
class MyUploader < CarrierWave::Uploader::Base
  def move_to_cache
    true
  end

  def move_to_store
    true
  end
end
```

When the `move_to_cache` and/or `move_to_store` methods return true, files will be moved (instead of copied) to the cache and store respectively.

This has only been tested with the local filesystem store.

## Skipping ActiveRecord callbacks

By default, mounting an uploader into an ActiveRecord model will add a few
callbacks. For example, this code:

```ruby
class User
  mount_uploader :avatar, AvatarUploader
end
```

Will add these callbacks:

```ruby
before_save :write_avatar_identifier
after_save :store_previous_changes_for_avatar
after_commit :remove_avatar!, on: :destroy
after_commit :mark_remove_avatar_false, on: :update
after_commit :remove_previously_stored_avatar, on: :update
after_commit :store_avatar!, on: [:create, :update]
```

If you want to skip any of these callbacks (eg. you want to keep the existing
avatar, even after uploading a new one), you can use ActiveRecord’s
`skip_callback` method.

```ruby
class User
  mount_uploader :avatar, AvatarUploader
  skip_callback :commit, :after, :remove_previously_stored_avatar
end
```

## Uploader Callbacks

In addition to the ActiveRecord callbacks described above, uploaders also have callbacks.

```ruby
class MyUploader < ::CarrierWave::Uploader::Base
  before :remove, :log_removal
  private
  def log_removal
    ::Rails.logger.info(format('Deleting file on S3: %s', @file))
  end
end
```

Uploader callbacks can be `before` or `after` the following events:

```
cache
process
remove
retrieve_from_cache
retrieve_from_store
store
```

## Contributing to CarrierWave

See [CONTRIBUTING.md](https://github.com/carrierwaveuploader/carrierwave/blob/master/CONTRIBUTING.md)

## License

The MIT License (MIT)

Copyright (c) 2008 Jonas Nicklas

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
