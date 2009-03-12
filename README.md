# CarrierWave

This plugin for Merb and Rails provides a simple and extremely flexible way to upload files.

## Getting Started

Install the latest stable release:

    [sudo] gem install carrierwave

Or the cutting edge development version:

    [sudo] gem install jnicklas-carrierwave --source http://gems.github.com

In Merb, add it as a dependency to your config/dependencies.rb:
    
    dependency 'carrierwave'

In Rails, add it to your environment.rb:

    config.gem "carrierwave"

## Quick Start

Start off by generating an uploader:

    merb-gen uploader Avatar

or in Rails:

    script/generate uploader Avatar

this should give you a file in:

    app/uploaders/avatar_uploader.rb

Check out this file for some hints on how you can customize your uploader. It should look something like this:

    class AvatarUploader < CarrierWave::Uploader
      storage :file
    end

You can use your uploader class to store and retrieve files like this:

    uploader = AvatarUploader.new
    
    uploader.store!(my_file)
    
    uploader.retrieve_from_store!('my_file.png')

CarrierWave gives you a `store` for permanent storage, and a `cache` for temporary storage. You can use different stores, at the moment a filesystem store and an Amazon S3 store are bundled.

Most of the time you are going to want to use CarrierWave together with an ORM. It is quite simple to mount uploaders on columns in your model, so you can simply assign files and get going:

### ActiveRecord

First require the activerecord extension:

    require 'carrierwave/orm/activerecord

You don't need to do this if you are using Merb or Rails.

Open your model file, and do something like:

    class User < ActiveRecord::Base
      mount_uploader :avatar, AvatarUploader
    end

Now you can upload files!

    u = User.new
    u.avatar = params[:file]
    u.avatar = File.open('somewhere')
    u.save!
    u.avatar.url # => '/url/to/file.png'
    u.avatar.current_path # => 'path/to/file.png'

### DataMapper

First require the activerecord extension:

    require 'carrierwave/orm/datamapper

You don't need to do this if you are using Merb or Rails.

Open your model file, and do something like:

    class User
      include DataMapper::Resource

      mount_uploader :avatar, AvatarUploader
    end

Now you can upload files!

    u = User.new
    u.avatar = params[:file]
    u.avatar = File.open('somewhere')
    u.save!
    u.avatar.url # => '/url/to/file.png'
    u.avatar.current_path # => 'path/to/file.png'

## Changing the storage directory

In order to change where uploaded files are put, just override the `store_dir` method:

    class MyUploader < CarrierWave::Uploader
      def store_dir
        'public/my/upload/directory'
      end
    end

This works for the file storage as well as Amazon S3.

## Adding versions

Often you'll want to add different versions of the same file. The classic example is image thumbnails. There is built in support for this:

    class MyUploader < CarrierWave::Uploader
      include CarrierWave::RMagick
      
      process :resize => [800, 800]

      version :thumb do
        process :crop_resized => [200,200]
      end
      
    end

When this uploader is used, an uploaded image would be scaled to be no larger than 800 by 800 pixels. A version called thumb is then created, which is scaled and cropped to exactly 200 by 200 pixels. The uploader could be used like this:

    uploader = AvatarUploader.new
    uploader.store!(my_file)                              # size: 1024x768
    
    uploader.url # => '/url/to/my_file.png'               # size: 800x600
    uploader.thumb.url # => '/url/to/thumb_my_file.png'   # size: 200x200

One important thing to remember is that process is called *before* versions are created. This can cut down on processing cost.

## Making uploads work across form redisplays

Often you'll notice that uploaded files disappear when a validation
fails. CarrierWave has a feature that makes it easy to remember the
uploaded file even in that case. Suppose your `user` model has an uploader mounted on `avatar` file, just add a hidden field called `avatar_cache`.
In Rails, this would look like this:

    <% form_for @user do |f| %>
      <p>
        <label>My Avatar</label>
        <%= f.file_field :avatar %>
        <%= f.hidden_field :avatar_cache %>
      </p>
    <% end %>

It might be a good idea to show th user that a file has been uploaded,
in the case of images, a small thumbnail would be a good indicator:

    <% form_for @user do |f| %>
      <p>
        <label>My Avatar</label>
        <%= image_tag(@user.avatar.url) if @user.avatar %>
        <%= f.file_field :avatar %>
        <%= f.hidden_field :avatar_cache %>
      </p>
    <% end %>

## What's in that uploader file?

The fact that uploaders are separate classes in CarrierWave is a big advantage. What this means for you is:

#### Less magic

In order to customize your uploader, all you need to do is override methods and use normal, clear and simple Ruby code. That means no `alias_method_chain`'ing to hook into the upload process, no messing around with weird extensions. The code in CarrierWave is very simple and easy because of this.

#### Easier to test

How do you test file uploads? I always found this ridiculously hard. A separate class means you can test is separately, which is nicer, easier and more maintainable.

#### More Flexible

Many of the things you can do in CarrierWave are hard, or impossible to do in other file upload plugins, and have previously required you to roll your own. Now you can get all the flexibility without having to write low level stuff.

#### Easy to extend

CarrierWave has support for a few different image manipulation libraries. These need *no* code to hook into CarrierWave, because they are simple modules. If you want to write your own manipulation library (doesn't need to be for images), you can do the same.

## Using Amazon S3

You'll need to configure a bucket, access id and secret key like this:

    CarrierWave.config[:s3][:access_key_id] = 'xxxxxx'
    CarrierWave.config[:s3][:secret_access_key] = 'xxxxxx'
    CarrierWave.config[:s3][:bucket] = 'name_of_bucket'

Do this in an initializer in Rails, and in a `before_app_loads` block in Merb.

And then in your uploader, set the storage to :s3

    class AvatarUploader < CarrierWave::Uploader
      storage :s3
    end

That's it! You can still use the `CarrierWave::Uploader#url` method to return the url to the file on Amazon S3

## Using RMagick

If you're uploading images, you'll probably want to manipulate them in some way, you might want to create thumbnail images for example. CarrierWave comes with a small library to make manipulating images with RMagick easier. It's not loaded by default so you'll need to require it:

    require 'carrierwave/processing/rmagick'

You'll also need to include it in your Uploader:

    class AvatarUploader < CarrierWave::Uploader
      include CarrierWave::RMagick
    end

The RMagick module gives you a few methods, like `CarrierWave::RMagick#crop_resized` which manipulate the image file in some way. You can set a `process` callback, which will call that method any time a file is uploaded.

    class AvatarUploader < CarrierWave::Uploader
      include CarrierWave::RMagick
      
      process :crop_resized => [200, 200]
      process :convert => 'png'
      
      def filename
        super + '.png'
      end
    end

Check out the manipulate! method, which makes it easy for you to write your own manipulation methods.

## Using ImageScience

ImageScience works the same way as RMagick. As with RMagick you'll need to require it:

    require 'carrierwave/processing/image_science'

And then include it in your model:

    class AvatarUploader < CarrierWave::Uploader
      include CarrierWave::ImageScience
      
      process :crop_resized => [200, 200]
    end

## Read the source

CarrierWave is still young, but most of it is pretty well documented. Just dig in and look at the source for more in-depth explanation of what things are doing.