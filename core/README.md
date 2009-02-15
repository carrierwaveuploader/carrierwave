# Merb Upload

This plugin for Merb provides a simple and extremely flexible way to upload files.

## Getting Started

At the moment you are going to have to grab it here from github and install it yourself.

Add it as a dependency to your config/init.rb
    
    dependency 'merb_upload'

## Quick Start

Most of the time you are going to want to use Merb Upload together with an ORM, store the file on the filesystem and a location for it in the database. This should get you going:

### ActiveRecord

First, install the `merb_upload_activerecord` gem from more. Add it as a dependency. Generate an uploader like this:

    merb-gen uploader Avatar

this should give you a file in:

    app/uploaders/avatar_uploader.rb

Check out this file for some hints on how you can customize your uploader.

Open your model file, and do something like:

    class User < ActiveRecord::Base
    
      mount_uploader :avatar, AvatarUploader

    end

Now you can upload files!

    u = User.new
    u.avatar = params[:file]
    u.avatar = File.open('somewhere')
    u.save!
    u.url # => '/url/to/file.png'
    u.current_path # => 'path/to/file.png'

### DataMapper

First, install the `merb_upload_datamapper` gem from more. Add it as a dependency. Generate an uploader like this:

    merb-gen uploader Avatar

this should give you a file in:

    app/uploaders/avatar_uploader.rb

Check out this file for some hints on how you can customize your uploader.

Open your model file, and do something like:

    class User
    
      include DataMapper::Resource
      extend Merb::Upload::DataMapper

      mount_uploader :avatar, AvatarUploader

    end

Now you can upload files!

    u = User.new
    u.avatar = params[:file]
    u.avatar = File.open('somewhere')
    u.save!
    u.url # => '/url/to/file.png'
    u.current_path # => 'path/to/file.png'

## What's in that uploader file?

The fact that uploaders are separate classes in Merb Upload is a big advantage. What this means for you is:

#### Less magic

In order to customize your uploader, all you need to do is override methods and use normal, clear and simple Ruby code. That means no `alias_method_chain`'ing to hook into the upload process, no messing around with weird extensions. The code in Merb Upload is very simple and easy because of this.

#### Easier to test

How do you test file uploads? I always found this ridiculously hard. A separate class means you can test is separately, which is nicer, easier and more maintainable.

#### More Flexible

Many of the things you can do in Merb Upload are hard, or impossible to do in other file upload plugins, and have previously required you to roll your own. Now you can get all the flexibility without having to write low level stuff.

#### Easy to extend

Merb Upload has support for a few different image manipulation libraries in more. These need *no* code to hook into Merb Upload, because they are simple modules. If you want to write your own manipulation library (doesn't need to be for images), you can do the same.

## Read the source

Merb Upload is still young, but most of it is pretty well documented. Just dig in and look at the source for more in-depth explanation of what things are doing.