# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 0.11.0 - 2016-03-29

[Compare v0.10.0...v0.11.0](https://github.com/carrierwaveuploader/carrierwave/compare/v0.10.0...v0.11.0)

### Added
* Add a test matcher for the format (@yanivpr [#1758](https://github.com/carrierwaveuploader/carrierwave/pull/1758))
* Support of MiniMagick's Combine options (@bernabas [#1754](https://github.com/carrierwaveuploader/carrierwave/pull/1754))
* Validate with the actual content-type of files (@eavgerinos)
* Support for multiple file uploads with `mount_uploaders` method (@jnicklas and @lisarutan [#1481](https://github.com/carrierwaveuploader/carrierwave/pull/1481))
* Add a `cache_only` configuration option, useful for testing (@jeffkreeftmeijer [#1456](https://github.com/carrierwaveuploader/carrierwave/pull/1456))
* Add `#width` and `#height` methods to MiniMagick processor (@ShivaVS [#1405](https://github.com/carrierwaveuploader/carrierwave/pull/1405))
* Add `#width` and `#height` methods to the RMagick processor (@mehlah [#1805](https://github.com/carrierwaveuploader/carrierwave/pull/1805))
* Support for jRuby (@lephyrius [#1377](https://github.com/carrierwaveuploader/carrierwave/pull/1377))
* Make cache storage configurable (@mshibuya [#1312](https://github.com/carrierwaveuploader/carrierwave/pull/1312))
* Errors on file size (@gautampunhani [#1026](https://github.com/carrierwaveuploader/carrierwave/pull/1026))
* Add Indonesian, Taiwanese and Chinese i18n translations for errors (@saveav, @st0012, @msyesyan)

### Changed
* [BREAKING CHANGE] Allow non-ASCII filename by default (@shuhei [#1772](https://github.com/carrierwaveuploader/carrierwave/pull/1772))
* [BREAKING CHANGE] `to_json` behavior changed when serializing an uploader (@jnicklas and @lisarutan [#1481](https://github.com/carrierwaveuploader/carrierwave/pull/1481))
* [BREAKING CHANGE] Rename `extension_white_list` ~> `extension_whitelist` (@mehlah [#1819](https://github.com/carrierwaveuploader/carrierwave/pull/1819))
* [BREAKING CHANGE] Rename `extension_black_list` ~> `extension_blacklist` (@mehlah [#1819](https://github.com/carrierwaveuploader/carrierwave/pull/1819))
* [BREAKING CHANGE] Rename i18n keys `extension_black_list_error` ~> `extension_blacklist_error` and `extension_white_list_error` ~> `extension_whitelist_error` (@mehlah)
* `cache_id` is now less collision-prone thanks to a counter (@stillwaiting [#1797](https://github.com/carrierwaveuploader/carrierwave/pull/1797))
* Better error when the configured storage is unknown (@st0012 [#1779](https://github.com/carrierwaveuploader/carrierwave/pull/1779))
* Allow to pass additionnal options to Rackspace `authenticated_url` (@duhast [#1722](https://github.com/carrierwaveuploader/carrierwave/pull/1722))
* Reduced memory footprint (@schneems [#1652](https://github.com/carrierwaveuploader/carrierwave/pull/1652), @simonprev [#1706](https://github.com/carrierwaveuploader/carrierwave/pull/1706))
* Improve Fog Loading (@plribeiro3000 [#1620](https://github.com/carrierwaveuploader/carrierwave/pull/1620), @eavgerinos)
* All locales from `config.i18n.available_locales` are added to load_path (@printercu [#1521](https://github.com/carrierwaveuploader/carrierwave/pull/1521))
* Do not display RMagick exception in I18n message (manuelpradal [#1361](https://github.com/carrierwaveuploader/carrierwave/pull/1361))
* `#default_url` now accepts the same args passed to `#url` (@shekibobo [#1347](https://github.com/carrierwaveuploader/carrierwave/pull/1347))
* Accept an array of strings or regexps to white/blacklist content types (@mehlah [#1816](https://github.com/carrierwaveuploader/carrierwave/pull/1816))
* `#content_type_whitelist` and `extension_whitelist` now takes either a string, a regexp, or an array of values (same thing for blacklists) (@mehlah [#1825](https://github.com/carrierwaveuploader/carrierwave/pull/1825))
* Blank uploaders are now memoized on the model instance (@DarthSim [#1860](https://github.com/carrierwaveuploader/carrierwave/pull/1860))

### Removed
* Remove `CarrierWave::MimeTypes` processor module (@mehlah [#1813](https://github.com/carrierwaveuploader/carrierwave/pull/1813))
* Remove `CarrierWave::MagicMimeTypes` processor module (@mehlah [#1816](https://github.com/carrierwaveuploader/carrierwave/pull/1816))
* Remove dependency on `ruby-filemagic` in white/blacklist content types (@mehlah [#1816](https://github.com/carrierwaveuploader/carrierwave/pull/1816))

### Fixed
* Fix `Mounter.blank?` method (@Bonias [#1746](https://github.com/carrierwaveuploader/carrierwave/pull/1746))
* Reset `remove_#{column}` after invoking `remove_#{column}` (@eavgerinos [#1668](https://github.com/carrierwaveuploader/carrierwave/pull/1668))
* Change Google's url to the `public_url` (@m7moud [#1683](https://github.com/carrierwaveuploader/carrierwave/pull/1683))
* Do not write to `ActiveModel::Dirty` changes when assigning something blank to a mounter that was originally blank (@eavgerinos [#1635](https://github.com/carrierwaveuploader/carrierwave/pull/1635))
* Various grammar and typos fixes to error messages translations
* Don't error when size is called on a deleted file (@danielevans [#1561](https://github.com/carrierwaveuploader/carrierwave/pull/1561))
* Flush mounters on `#dup` of active record model (@danielevans [#1544](https://github.com/carrierwaveuploader/carrierwave/pull/1544))
* `Fog::File.read` returns its contents after upload instead of "closed stream" error (@stormsilver [#1517](https://github.com/carrierwaveuploader/carrierwave/pull/1517))
* Don't read file twice when calling `sanitized_file` or `cache!` (@felixbuenemann [#1476](https://github.com/carrierwaveuploader/carrierwave/pull/1476))
* Change image extension when converting formats (@nashby [#1446](https://github.com/carrierwaveuploader/carrierwave/pull/1446))
* Fix file delete being called twice on remove (@adamcrown [#1441](https://github.com/carrierwaveuploader/carrierwave/pull/1441))
* RSpec 3 support (@randoum #1421[](https://github.com/carrierwaveuploader/carrierwave/pull/1421), @akiomik [#1370](https://github.com/carrierwaveuploader/carrierwave/pull/1370))
* MiniMagick convert to a format all the pages by default and accept an optional page number parameter to convert specific pages (@harikrishnan83 [#1408](https://github.com/carrierwaveuploader/carrierwave/pull/1408))
* Fix cache workfile collision between versions (@jvdp [#1399](https://github.com/carrierwaveuploader/carrierwave/pull/1399))
* Reset mounter cache on record reload (@semenyukdmitriy [#1383](https://github.com/carrierwaveuploader/carrierwave/pull/1383))
* Retrieve only active versions of files (@filipegiusti [#1351](https://github.com/carrierwaveuploader/carrierwave/pull/1351))
* Fix default gravity in MiniMagick `resize_and_pad` (@abevoelker [#1358](https://github.com/carrierwaveuploader/carrierwave/pull/1358))
* Skip loading RMagick if already loaded (@mshibuya [#1346](https://github.com/carrierwaveuploader/carrierwave/pull/1346))
* Make the `#remove_#{column}` accessor set the mounted column as changed (@nikz [#1326](https://github.com/carrierwaveuploader/carrierwave/pull/1326))
* Tempfile and @content_type assignment (@bensie [#1487](https://github.com/carrierwaveuploader/carrierwave/issues/1487))

## 0.10.0 - 2014-02-26

Please check [0.10-stable] for previous changes.

[0.10-stable]: https://github.com/carrierwaveuploader/carrierwave/blob/0.10-stable/History.txt
