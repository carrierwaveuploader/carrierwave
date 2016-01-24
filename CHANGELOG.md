# Carrierwave History/Changelog

## [Unreleased]
### Added
* Add a test matcher for the format (@yanivpr)
* Add Indonesian i18n translations for errors (@saveav)
* Support of MiniMagick's Combine options (@bernabas)
* Add Taiwanese i18n translations for errors (@st0012)
* Validate with the actual content-type of files (@eavgerinos)
* Add Chinese i18n translations for errors [msyesyan]
* Support setting a SanitizedFile where the content_type is found on the `:type` key of the file hash (@bensie)
* Support for multiple file uploads with `mount_uploaders` method (@jnicklas and @lisarutan)
* Add a `cache_only` configuration option, useful for testing (@jeffkreeftmeijer)
* Add `#width` and `#height` methods to MiniMagick processor (@ShivaVS)
* Support for jRuby (@lephyrius)
* Make cache storage configurable (@mshibuya)
* Errors on file size (@gautampunhani)

### Changed
* [BREAKING CHANGE] Allow non-ASCII filename by default (@shuhei)
* [BREAKING CHANGE] `to_json` behavior changed when serializing an uploader (@jnicklas and @lisarutan)
* Better error when the configured storage is unknown (@st0012)
* Allow to pass additionnal options to Rackspace `authenticated_url` (@duhast)
* Reduced memory footprint (@schneems, @simonprev)
* Improve Fog Loading (@plribeiro3000, @eavgerinos)
* All locales from `config.i18n.available_locales` are added to load_path (@printercu)
* Do not display rmagick exception in I18n message (manuelpradal)
* `#default_url` now accepts the same args passed to `#url` (@shekibobo)

### Deprecated

### Removed

### Fixed
* Fix `Mounter.blank?` method (@Bonias)
* Reset `remove_#{column}` after invoking `remove_#{column}` (@eavgerinos)
* Change Google's url to the public_url (@m7moud)
* Do not write to ActiveModel::Dirty changes when assigning something blank to a mounter that was originally blank (@eavgerinos)
* Various grammar and typos fixes to error messages translations
* Don't error when size is called on a deleted file (@danielevans)
* Flush mounters on dup of active record model(@danielevans)
* Fog::File.read returns its contents after upload instead of "closed stream" error (@stormsilver)
* Don't read file twice when calling `sanitized_file` or `cache!` (@felixbuenemann)
* Change image extension when converting formats (@nashby)
* Fix file delete being called twice on remove (@adamcrown)
* RSpec 3 support
* MiniMagick convert to a format all the pages by default and accept an optional page number parameter to convert specific pages (@harikrishnan83)
* Fix cache workfile collision between versions (@jvdp)
* Reset mounter cache on record reload (@semenyukdmitriy)
* Retrieve only active versions of files (@filipegiusti)
* Fix default gravity in MiniMagick resize_and_pad (@abevoelker)
* Skip loading RMagick if already loaded (@mshibuya)
* Make the `#remove_*` accessor set the mounted column as changed (@nikz)

Please check [0.10-stable] for previous changes.

[Unreleased]: https://github.com/carrierwaveuploader/carrierwave/compare/v0.10.0...HEAD
[0.10-stable]: https://github.com/carrierwaveuploader/carrierwave/blob/0.10-stable/History.txt
