# Carrierwave History/Changelog

## Version 0.10.0 2014-02-26

* [changed] Memoize uploaders and uploader_options (Derek Parker and Joshua Davey from Hashrocket)
* [changed] Don't force pad background color to white in `resize_and_pad` (@fnordfish)
* [changed] Remove auth access information when parsing URL for filename (@nddeluca)
* [changed] Read Content type from cached and uploaded file, adds mime-types as hard dependency
* [added] Added authenticated_url functionality for Openstack storage (@snoopie)
* [added] Add Polish I18n translations for errors (@ArturT)
* [added] Add Greek locale for error messages (@agorf)
* [added] Add French locale for error messages (@gdurelle)
* [added] Add Japanese locale for error messages (@tomodian)
* [added] Add Norwegian locale for error messages (@theodorton)
* [added] Add Portuguese locale for error messages (@pedrosmmoreira)
* [fixed] Overridden serializable_hash accepts an options hash (@bensie)
* [fixed] Fog connection object performance issues (@taavo)
* [fixed] Delete Tempfile after manipulate with MiniMagick (@dimko)
* [fixed] Ensure `#remove_#{column}` and `#remove_#{column}` return false after committing with ActiveRecord (@bensie)
* [fixed] Fix issue with content-disposition existing with no filename when downloading, reports that Google does this (@hasghari / @bensie / @taavo)

## Version 0.9.0 2013-07-06

* [BREAKING CHANGE] Use integer time (UTC) to generate cache IDs [@bensie]
* [changed] Recommend using ActionController::Base.helpers instead of Sprockets::Rails::Helper for asset pipeline [@c0]
* [changed] Lots of URL encoding fixes [@taavo]
* [added] Added #version_exists? method [@tmaier]
* [added] Added configuration param (`:fog_use_ssl_for_aws`) to disable SSL for public_url [@pbzymek]
* [added] Add Dutch i18n translations for errors [@vanderhoorn]
* [added] Add Czech i18n translations for errors [@elmariofredo]
* [added] Add German i18n translations for errors [@felixbuenemann]
* [fixed] Gemspec error in Ruby 2.0.0 [@sanemat]
* [fixed] Fixed bug in serializing to xml or json where both :only and :except are passed [@Knack]
* [fixed] Fix recreate_versions! when version if proc returns false [@arthurnn]

## Version 0.8.0 2013-01-08

* [BREAKING CHANGE] Remove 'fog\_endpoint' in favor of 'host' and/or 'endpoint' in fog_credentials [bensie]
* [changed] Remove autoload in favor of standard 'require' to help with thread safety [bensie]
* [added] Allow recreating only specified versions instead of all versions [div]
* [added] Add support for S3-compliant storage APIs that are not actually S3 [neuhausler]
* [added] Add #extension CarrierWave::Storage::Fog::File for fetching a file extension [sweatypitts]
* [fixed] Marshaling uploader objects no longer raises a TypeError on anonymous classes [bensie]

## Version 0.7.1 2012-11-08

* [added] add a override to allow fog configuration per uploader [dei79]
* [fixed] Fix a regression when removing uploads [mattolson]

## Version 0.7.0 2012-10-19

* [BREAKING CHANGE] Rename 'fog\_host' config option to 'asset_host' and add support for file storage [DouweM]
* [changed] Changed after\_destroy with after\_commit ... :on => :destroy [Cristian Sorinel]
* [changed] Do not handle any special cases for URL handling, keep the existing escape/unescape functionality and allow overriding [bensie]
* [changed] Activerecord-deprecated_finders gem was renamed [bensie]
* [changed] Removed unnecessary present? method from ActiveSupport [Yauheni Kryudziuk]
* [changed] Use AWS S3 subdomain URL when directory name contains a period. [DouweM]
* [added] Added `resize_to_geometry_string` RMagick method that will scale image [wprater]
* [added] Made feature to blacklist certain extensions [thiagofm]
* [added] Parse and pass fog_host option to ::Fog::Storage [Yauheni Kryudziuk]
* [added] Add serialization spec for multiple uploaders. [malclocke]
* [added] Add :read option to manipulate! [xtreme-tanzeeb-khalili]
* [added] Add binary/octet-stream as generic mime type. [phiggins]
* [added] Add 'fog_endpoint' config option to set an alternate Fog host. [DouweM]
* [fixed] Fixed can't convert File into String [jnimety]
* [fixed] Fixed an issue when parsing URL w/o schema. [Yauheni Kryudziuk]
* [fixed] Fix reference to column in serializable_hash [malclocke]
* [fixed] Fix inconsistence in file API [oelmekki]

## Version 0.6.2 2012-04-12

* [fixed] Don't double-generate cache_id [skyeagle]
* [added] Escape plus signs (+) in remote URLs [adrianpike]
* [added] Enhance multi-page PDF support in RMagick [xtreme-tanzeeb-khalili]

## Version 0.6.1 2012-04-02

* [fixed] Calling #serializable_hash with no options [matthewrudy]

## Version 0.6.0 2012-03-27

* [BREAKING CHANGE] Require Rails 3.2 or Rails master (4.0) - depends on activesupport/activemodel [bensie]
* [BREAKING CHANGE] Remove :S3 storage option in favor of Fog [bensie]
* [BREAKING CHANGE] Remove :CloudFiles storage option in favor of Fog [bensie]
* [changed] JSON / XML serialization hashes are consistent and work as expected with ActiveRecord's serializable_hash [bensie]
* [added] fog_host now accepts a proc (useful for dynamic asset servers) [jtrim]
* [added] Add ability to process a version from an existing version so you aren't always crunching the original, large file [ferblape]
* [added] Allow brackets in remote URLs [ngauthier]
* [added] CarrierWave::Storage::Fog::File#exists? to check the existence of the file without needing to fetch it [bensie]
* [added] Gravity option on `resize_to_fill` (minimagick) [TheOddLinguist]
* [added] Add query options for s3 to support response headers overwriting [meceo]
* [added] Make storages File#url methods to work without any params [meceo]
* [added] Set the CarrierWave.root correctly if Padrino is defined [futurechimp]
* [added] Cache fog connections for improved performance [labocho]
* [fixed] Fix slow fetching of content-length on remote file [geemus]
* [fixed] Fog remote specs now passing and depend on Fog >= 1.3.1 [geemus]
* [fixed] Fix an issue where multi-page PDFs can't be converted with RMagick [chanind]
* [fixed] MiniMagick expects string args to mogrify commands [bensie]
* [fixed] With Active Record ORM, setting remote_url marks mounted column as dirty [trevorturk]
* [fixed] Fix possible race condition with CarrierWave.root [bensie]
* [fixed] ActiveSupport::Memoizable deprecation warning [slbug]

## Version 0.5.8 2011-11-10

* [added] Allow custom error messages [bartt]
* [added] Add config.base_path to use as a prefix for uploader URLs [die-antwort]
* [added] Support fog streaming uploads [chrisdurtschi]
* [added] Support `move_to` in addition to the default `copy_to` when using the cache [jasonydes]
* [fixed] Support for Sinatra 1.3 (with backward compatibility) [bensie]
* [fixed] Fog `get_object_url` deprecated, use `get_object_https_url` or `get_object_http_url` [scottmessinger]

## Version 0.5.7 2011-08-12

* [BREAKING CHANGE] Extracted Mongoid support into a separate gem (carrierwave-mongoid) [jnicklas]
* [BREAKING CHANGE] Remove ImageScience support due to lack maintenance and 1.9.2 compatibility [jnicklas]
* [BREAKING CHANGE] Combine `delete_tmp_file_after_storage` and `delete_cache_id_after_storage` options [bensie]
* [changed] Cached and then remote-uploaded file will no longer have a content_type, please use CarrierWave::MimeTypes processor instead [trevorturk]
* [changed] Allow writing over a previously assigned file when retrieving a remote file [Florent2]
* [fixed] Fixed exception when nested or double-embedded Mongoid documents are saved [potatosalad]
* [fixed] Fixed that store! can call process! twice [gzigzigzeo]
* [fixed] Performance enhancements by reducing use of rescue [jamescook]

## Version 0.5.6 2011-07-12

* [fixed] Remove cache file and directories after storing [scottwb]
* [fixed] Add missing active_support/deprecation require [trevorturk]
* [fixed] Remove redundant requires of sequel and datamapper [solnic]
* [fixed] Running tests with REMOTE=true [geemus]

## Version 0.5.5 2011-07-09

* [BREAKING CHANGE] Extracted DataMapper support into a separate gem (carrierwave-datamapper) [jnicklas]
* [BREAKING CHANGE] Extracted Sequel support into a separate gem (carrierwave-sequel) [jnicklas]
* [changed] Don't downcase filenames by default [bensie]
* [changed] Orm mount modules default uploader to nil [jnicklas]
* [changed] Remove alias_method :blank? from SanitizedFile to for performance re: issue #298 [trevorturk]
* [added] Conditional processing of versions [gucki]
* [added] Remove Remove previously stored files after Active Record mounted uploader update re: issue #75 [trevorturk]
* [added] Remove Remove previously stored files after Mongoid mounted uploader update re: issue #75 [did]
* [added] Added _identifier to retrieve identifier/filename [jnicklas]
* [added] `clean_cached_files!` clears all files older than 24 hours by default, but time frame can now be customized [cover]
* [added] Versions now implement an enable_processing method which uses the parent when no value is set [mariovisic]
* [added] Delete cache_id garbage dirs, closes GH issue #338 [clyfe]
* [added] Added CarrierWave::MimeTypes processor for more advanced content-type guessing [JangoSteve]
* [fixed] Active Record's `will_change!` method works when `mount_on` option is used [indrekj]
* [fixed] Fixed problem with accepting URL uploads when the URL was already escaped [cover]
* [fixed] Fixed ability to override sanitize_regexp [trevorturk]
* [fixed] Fix that cached and then remote-uploaded file should have content_type [trevorturk]
* [fixed] Fix `validates_size/length_of` in Rails 3.0.6 and above, closes #342 [bensie]
* [fixed] Various Active Support compatibility updates [slbug, bensie, et al]

## Version 0.5.4 2011-05-18

* [changed] Fog: Performance enhancements for AWS and Google [geemus]
* [changed] Fog: Try to use subdomain public url on s3 [geemus]
* [changed] Memoize CarrierWave::Mounter#option for increased performance [ingemar]
* [changed] Relax development gem dependency versions where possible and fix tests [trevorturk]
* [changed] Upgrade to RSpec 2 [jnicklas]

## Version 0.5.3 2011-03-22

* [changed] Cloud Files storage so delete and url return nil if object not found instead of exception [minter]
* [added] New fog storage provider that supports Amazon S3, Rackspace Cloud Files, and Google Storare for Developers [geemus]
* [added] `cloud_files_auth_url` and `cloud_files_snet` config options for Cloud Files [minter]
* [added] process_uri method that can be overridden in your uploader to support downloads from non-standard urls [trevorturk]
* [added] version urls to json output [karb]
* [added] Active Record marks uploader column as changed when changed [josevalim]
* [fixed] Cloud Files storage tests to use the new url format [minter]
* [fixed] Moved raising of FormNotMultipart farther down to avoid errors with nested attribute forms [trevorturk]
* [fixed] original_filename of remote uploads should be calculated from final (possibly redirected) URL [brady8]
* [fixed] Fix calling :process! on files stored in remote solutions [alexcrichton]
* [fixed] Fix paperclip compatibility mappings [valakirka]
* [fixed] Ensure temporary files can be deleted on Windows [Eleo]

## Version 0.5.2 2011-02-18

* [changed] Require `active_support/core_ext/string/multibyte` to fix downcasing unicode filenames during sanitizing [nashbridges]
* [changed] Use fog ~> 0.4, Fog::AWS::Storage.new -> Fog::Storage.new(:provider => 'AWS') [trevorturk]
* [changed] Use class_attribute (inheritable attributes are deprecated) [stephencelis]
* [changed] `extension_white_list` no longer supports a single string, only an array of strings and/or Regexps [trevorturk]
* [changed] Rackspace Cloud Files: only create container if container does not exist [edmundsalvacion]
* [changed] GridFS: the path returned is no longer always nil, it is now the path in GridFS [alexcrichton]
* [added] Ability to specify a Regexp in the `extension_white_list` [lwe]
* [added] CarrierWave::SanitizedFile#sanitize_regexp public method to allow customizing [trevorturk]
* [added] sanitize_regexp documentation to the README [nashbridges]
* [added] Ability to use https for Amazon S3 URLs if `config.s3_use_ssl` is true [recruitmilitary]
* [added] The s3_region configuration documentation to the README [mrsimo]
* [fixed] Reprocessing remotely stored files [alexcrichton]
* [fixed] Nested versioning processing [alexcrichton]
* [fixed] An intermittent bug with ImageScience `resize_to_fill` method [LupineDev]
* [fixed] DataMapper#save should remove the avatar if remove_avatar? returns true [wprater]

## Version 0.5.1 2010-12-01

* [changed] `s3_access` renamed to `s3_access_policy` [Jonas Nicklas]
* [changed] Depend on activesupport ~> 3.0 for Rails 3.1 compatibility [Trevor Turk]
* [changed] Use fog >= 0.3.0, fix deprecation warnings [Paul Elliott]
* [changed] Use `mini_magick ~> 2.3`, `MiniMagick::Image.from_file` becomes `MiniMagick::Image.open` [Fredrik Björk]
* [changed] Convert generic MiniMagick::Invalid into ProcessingError [Alex Crichton]
* [changed] Remove cached tmp file after storing for file store [Damien Mathieu]
* [added] s3_region config option to set AWS S3 region [Roger Campos]
* [added] Option to retain cached tmp file after storage (`delete_tmp_file_after_storage`) [Damien Mathieu]
* [added] Transparent support for authenticated_read on S3 [Jonas Nicklas]
* [fixed] Clean up internal require statements [Josh Kalderimis]
* [fixed] Header support for S3 [Alex Crichton]
* [fixed] Stack level too deep errors when using to_json [Trevor Turk]
* [fixed] Documentation for mount_uploader [Nathan Kleyn]

## Version 0.5 2010-09-23

* [changed] Use ActiveModel instead of ActiveRecord validations to support Mongoid validations as well [Jeroen van Dijk, saberma]
* [changed] Support S3 file storage with the fog gem, instead of the aws gem (Trevor Turk)
* [changed] Move translations to a YAML file (Josh Kalderimis)
* [changed] Depend on activesupport ~> 3.0.0 instead of >= 3.0.0.rc (Trevor Turk)
* [changed] Remove old Merb and Rails generators, support Rails 3 generators (Jonas Nicklas, Trevor Turk)
* [changed] Replace Net::HTTP with open-url for remote file downloads (icebreaker)
* [changed] Move translations to a YAML file (Josh Kalderimis)
* [changed] Use gemspec to generate Gemfile contents (Jonas Nicklas)
* [added] Add file size support for S3 storage (Pavel Chipiga)
* [added] Add option for disabling multipart form check (Dennis Blöte)
* [fixed] Correct naming of validators (Josh Kalderimis)
* [fixed] Fix remote file downloader (Jonas Nicklas)
* [fixed] Escape URLs passed to remote file downloader so URLs with spaces work (Mauricio Zaffari)
* [fixed] Correct filename used in generators (Fred Wu)

## Version 0.4.6 2010-07-20

* [removed] Support for MongoMapper, see: http://groups.google.com/group/carrierwave/browse_thread/thread/56df146b83878c22
* [changed] AWS support now uses the aws gem, instead of using aws-s3 or right-aws as previously
* [added] `cloud_files_cdn_host` for Cloudfiles for performance gain
* [added] #recreate_versions! to recreate versions from base file
* [added] Support for MiniMagick in RSpec matchers
* [added] RMagick's `resize_to_fill` now takes an optional Gravity
* [fixed] Pass through options to to_json
* [fixed] Support new GridFS syntax for lates mongo gem
* [fixed] Validation errors are internationalized when the error is thrown, not on load
* [fixed] Rescue correct MiniMagick error
* [fixed] Support DataMapper 1.0
* [fixed] `SanitizedFile#copy_to` preserves content_type. Should fix GridFS content type not being set.

## Version 0.4.5 2010-02-20

* [added] Support for Rackspace Cloudfiles
* [added] GridFS now accepts a port
* [fixed] s3_headers is now properly initialized
* [fixed] work around DataMapper's patching of core method

## Version 0.4.4 2010-01-31

* [added] Support for downloading remote files
* [added] `CarrierWave.clean_cached_files!` to remove old cached files
* [added] Option to set headers for S3
* [added] GridStore now has authentication
* [fixed] Rmagick convert method now does what it says
* [fixed] Content type is stored on GridStore and Amazon S3
* [fixed] Metadata is no longer broken for S3

## Version 0.4.3 2009-12-19

* [fixed] cnamed URLs on S3 no longer have a third slash after http
* [fixed] fixed deprecation warnings on Rails 2.3.5

## Version 0.4.2 2009-11-26

* [added] RightAWS as an alternative S3 implementation
* [added] An option to enable/disable processing for tests
* [added] Mongoid ORM support
* [fixed] DataMapper now works both with and without dm-validations

## Version 0.4.1 2009-10-26

* [changed] Major changes to the ImageScience module, it actually works now!
* [fixed] Bug in configuration where it complais that it can't dup Symbol

* [removed] Support for Sequel < 2.12
* [removed] `crop_resized` and `resize` aliases in RMagick, use `resize_to_fill` and `resize_to_fit` respectively

## Version 0.4.0 2009-10-12

* [changed] the `public` option has been renamed `root` and the old `root` option was removed. No more ambiguity.
* [changed] Major *breaking* changes to the configuration syntax.

* [removed] support for `default_path`
* [removed] the `cache_to_cache_dir` option
* [removed] storage no longer calls `setup!` on storage engines

* [added] Support for MongoDB's GridFS store

## Version 0.3.4 2009-09-01

* [added] `default_url` as a replacement for `default_path`
* [deprecated] `default_path` is deprecated

## Version 0.3.4 2009-08-31

* [fixed] Deleting no longer causes TypeError in MongoMapper

## Version 0.3.3 2009-08-29

* [added] Support for MongoMapper
* [added] Support for CNamed Bucket URLs for Amazon S3

## Version 0.3.2 2009-07-18

Incremental upgrade

* [added] Ruby 1.9 compatibility
* [changed] Added Object#blank? implementation into CarrierWave, which removes any dpendencies on external libraries (extlib/activesupport)
* [fixed] Performance issues with S3 support
* [fixed] Sequel support for newer verions of Sequel (thanks Pavel!)

## Version 0.3.1 2009-07-01

A bugfix release. Drop in compatible with 0.3.0.

* [fixed] Saving a record with a mounted Uploader no longer removes uploaded file
* [fixed] The file returned by S3 storage now has the path set to the full store path
* [added] File returned by S3 storage now responds to S3 specific methods

## 0.3 2009-06-20

This is a stabilization release. Most features are now working as expected and
most bugs should be fixed.

* [changed] Reworked how storage engines work, some internal API changes
* [added] Macro-like methods for RMagick, no need to call #process any more!
* [added] Ability to super to any Mount method
* [fixed] Sequel support should now work as expected
* [fixed] ActiveRecord no longer saves the record twice
* [added] Added convenient macro style class methods to rmagick processing

## 0.2.4 2009-06-11

* [added] `resize_to_limit` method for rmagick
* [added] Now deletes files from Amazon S3 when record is destroyed

## 0.2.3 2009-05-13

* [changed] Mount now no longer returns nil if there is no stored file, it returns a blank uploader instead
* [added] Possibility to specify a default path
* [added] Paperclip compatibility module

## 0.2.1 2009-05-01

* [changed] Url method now optionally takes versions as parameters (like Paperclip)
* [added] A field which allows files to be removed with a checkbox in mount
* [added] Mount_on option for Mount, to be able to override the serialization column
* [added] Added demeter friendly column_url method to Mount
* [added] Option to not copy files to cache dir, to prevent writes on read only fs systems (this is a workaround and needs a better solution)

## 0.2 2009-04-15

* [changed] The version is no longer stored in the store dir. This will break the paths for files uploaded with 0.1
* [changed] CarrierWave::Uploader is now a module, not a class, so you need to include it, not inherit from it.
* [added] integrity checking in uploaders via a white list of extensions
* [added] Validations for integrity and processing in ActiveRecord, activated by default
* [added] Support for nested versions
* [added] Permissions option to set the permissions of the uploaded files
* [added] Support for Sequel
* [added] CarrierWave::Uploader#read to read the contents of the uploaded files

## 0.1 2009-03-12

This is a very experimental release that has not been well tested. All of the major features are in place though. Please note that there currently is a bug with load paths in Merb, which means you need to manually require uploaders.
