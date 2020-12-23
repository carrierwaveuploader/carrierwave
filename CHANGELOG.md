# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 2.1.0 - 2020-02-16

### Added

- Support authenticated_url for Blackblaze provider(@kevivmatrix [#2444](https://github.com/carrierwaveuploader/carrierwave/pull/2444))

### Fixed

- Fix Ruby 2.7 deprecations(@mshibuya [9a37fc9e](https://github.com/carrierwaveuploader/carrierwave/commit/9a37fc9e7ce2937c66d5419ce1943ed114385beb))
- Fix S3 path-style URL for host with dots for buckets that are placed in other regions than us-east-1(@Bonias [#2439](https://github.com/carrierwaveuploader/carrierwave/pull/2439))
- Make MiniMagick::Image constant absolute to prevent misleading 'uninitialized constant' error(@p8 [#2437](https://github.com/carrierwaveuploader/carrierwave/pull/2437))

## 2.0.2 - 2019-09-28

### Fixed

- Fix download causing nil error if the file has empty filename(@fukayatsu [#2419](https://github.com/carrierwaveuploader/carrierwave/pull/2419), [#2411](https://github.com/carrierwaveuploader/carrierwave/issues/2411))

## 2.0.1 - 2019-08-31

### Fixed

- Fix `#{column}_cache` unintentionally removing files on assigning empty string(@mshibuya [22e8005e](https://github.com/carrierwaveuploader/carrierwave/commit/22e8005e44751fbce9f088497853aa60b6c89fcc), [#2412](https://github.com/carrierwaveuploader/carrierwave/issues/2412))

## 2.0.0 - 2019-08-18

_No changes._

## 2.0.0.rc - 2019-06-23

### Added

- Append, reorder, and remove-single-file feature for multiple file uploader(@mshibuya [#2401](https://github.com/carrierwaveuploader/carrierwave/pull/2401))
- Allow retrieval of uploader index within uploaders(@mshibuya [#1771](https://github.com/carrierwaveuploader/carrierwave/issues/1771))
- Add ability to customize downloaders(@mshibuya [#1636](https://github.com/carrierwaveuploader/carrierwave/issues/1636))
- Support internationalized domain names for downloader(@mshibuya [#2086](https://github.com/carrierwaveuploader/carrierwave/issues/2086))
- Support authenticated_url for Aliyun provider(@Nitrino [#2381](https://github.com/carrierwaveuploader/carrierwave/pull/2381))
- Support passing options to authenticated_url for OpenStack provider(@stanhu [#2377](https://github.com/carrierwaveuploader/carrierwave/pull/2377))
- Support authenticated_url for AzureRM provider(@Nitrino [#2375](https://github.com/carrierwaveuploader/carrierwave/pull/2375))
- Allow custom expires_at when building an authenticated_url(@stephankaag [#2397](https://github.com/carrierwaveuploader/carrierwave/pull/2397))

### Changed

- Use the storage given by `storage` configuration also for `cache_storage` unless explicitly specified(@mshibuya [629afecb](https://github.com/carrierwaveuploader/carrierwave/commit/629afecbaeccd2300e4660b78ee36bd95dd845c5))
- Improve Fog initialization(@mshibuya [#2395](https://github.com/carrierwaveuploader/carrierwave/issues/2395))
- [BREAKING CHANGE] Multiple file uploader now keeps successful files on update, only discarding failed ones(@mshibuya [7db9195d](https://github.com/carrierwaveuploader/carrierwave/commit/7db9195de3197fcecfb442caa434369fe0e37846))
- [BREAKING CHANGE] `#remote_#{column}_urls=` was changed to preserve precedent updates(@mshibuya [8f18a95b](https://github.com/carrierwaveuploader/carrierwave/commit/8f18a95b74517ba96f6c571401d537f048e36961))
- `#serializable_hash` now returns string for version keys(@schovi [#2246](https://github.com/carrierwaveuploader/carrierwave/pull/2246))
- Use the MimeMagic gem to inspect file headers for the mime type. This allows for mitigation of CVE-2016-3714, in combination with a `content_type_whitelist`(@locriani [#1934](https://github.com/carrierwaveuploader/carrierwave/pull/1934))
- Replace mime-types dependency with mini_mime to save memory(@bradleypriest [#2292](https://github.com/carrierwaveuploader/carrierwave/pull/2292))
- Delegate MiniMagick processing to ImageProcessing gem(@janko [#2298](https://github.com/carrierwaveuploader/carrierwave/pull/2298))
- Handle ActiveRecord transaction correctly, not storing or removing files on rollback(@skosh [#2209](https://github.com/carrierwaveuploader/carrierwave/pull/2209))

### Deprecated

- `fog_provider` configuration was deprecated and has no effect, just adding fog providers to `Gemfile` will load them(@mshibuya [ca201ee2](https://github.com/carrierwaveuploader/carrierwave/commit/ca201ee2ceebe2d916be3bc1396fe381cc93afd7))
- `CarrierWave::Uploader::Base#sanitized_file` was deprecated, use `#file` instead(@mshibuya [28190e99](https://github.com/carrierwaveuploader/carrierwave/commit/28190e99299a6131c0424a5d10205f471e39f3cd))

### Removed

- Remove support for Rails 4.x and Ruby 2.0/2.1 (@mshibuya [bada043f](https://github.com/carrierwaveuploader/carrierwave/commit/bada043f39801625d748b9a89ef475eff5c8bdd5))

### Fixed

- Fix deleting files twice when marked for removal(@mshibuya [67800fde](https://github.com/carrierwaveuploader/carrierwave/commit/67800fdeb796a7b2efe1192e06f619dcc3c64f05))
- Fix `uploader.cache!` loads entire contents of file into memory(@mshibuya [#2136](https://github.com/carrierwaveuploader/carrierwave/issues/2136))
- Do not trigger \*\_will_change! when file is not to be removed(@mshibuya [#2323](https://github.com/carrierwaveuploader/carrierwave/issues/2323))
- Allow deleting all files for multiple file upload(@mshibuya [#1990](https://github.com/carrierwaveuploader/carrierwave/issues/1990))
- Failing to retrieve unquoted filenames from Content-Disposition(@mshibuya [#2364](https://github.com/carrierwaveuploader/carrierwave/issues/2364))
- Fix `#clean_cache!` breaking with old format of cache id(@mshibuya [aab402fb](https://github.com/carrierwaveuploader/carrierwave/commit/aab402fb5232c0ebfe2584c22c3fb0161613dc33))
- Fix `#exists?` returning true after Fog file deletion(@mshibuya [#2387](https://github.com/carrierwaveuploader/carrierwave/issues/2387))
- Make `#identifier` available for a retrieved file(@mshibuya [#1581](https://github.com/carrierwaveuploader/carrierwave/issues/1581))
- Make cache id generation less predictable(@mshibuya [#2326](https://github.com/carrierwaveuploader/carrierwave/issues/2326))
- Uploaders not being cleared when `#reload` or `#initialize_dup` are overridden in model(@mshibuya [#2379](https://github.com/carrierwaveuploader/carrierwave/issues/2379))
- Fix `#content_type` returning false, instead of nil(@longkt90 [#2384](https://github.com/carrierwaveuploader/carrierwave/pull/2384))
- Preserve connection cache when eagar-loading fog(@dmitryshagin [#2383](https://github.com/carrierwaveuploader/carrierwave/pull/2383))
- `#recreate_versions!` ignored `:from_version` when versions to recreate are given(@hedgesky [#1879](https://github.com/carrierwaveuploader/carrierwave/pull/1879) [#1164](https://github.com/carrierwaveuploader/carrierwave/issues/1164))

## 1.3.1 - 2018-12-29

### Fixed

- Fix `#url_options_supported?` causing nil error(@mshibuya [0b9a64a1](https://github.com/carrierwaveuploader/carrierwave/commit/0b9a64a1bb9f20d1de154dc3bf2e2dd988210220), [#2361](https://github.com/carrierwaveuploader/carrierwave/issues/2361))

## 1.3.0 - 2018-12-24

### Added

- Query parameter support for fog-google(@stanhu [#2332](https://github.com/carrierwaveuploader/carrierwave/pull/2332))
- Jets Turbine Support(@tongueroo [#2355](https://github.com/carrierwaveuploader/carrierwave/pull/2355))
- Add `allowed_types` to `content_type_whitelist_error`(@mhluska [#2270](https://github.com/carrierwaveuploader/carrierwave/pull/2270))

### Fixed

- S3 HTTPS url causes certificate issue when bucket name contains period(@ransombriggs [#2359](https://github.com/carrierwaveuploader/carrierwave/pull/2359))
- Failed to get image dimensions when image is cached but not stored yet(@artygus [#2349](https://github.com/carrierwaveuploader/carrierwave/pull/2349))
- Only include `x-amz-acl` header for AWS(@stanhu [#2356](https://github.com/carrierwaveuploader/carrierwave/pull/2356))
- Remove old caches when no space is left on disk(@dosuken123 [#2342](https://github.com/carrierwaveuploader/carrierwave/pull/2342))

## 1.2.3 - 2018-06-30

### Fixed

- Fix reading whole content of large files into memory on storing(@dosuken123 [#2314](https://github.com/carrierwaveuploader/carrierwave/pull/2314))

## 1.2.2 - 2018-01-02

### Fixed

- Reset Content-Type on converting file format(@kyoshidajp [#2237](https://github.com/carrierwaveuploader/carrierwave/pull/2237))

## 1.2.1 - 2017-10-04

### Fixed

- Locale check breaks when a Symbol is given to available_locales(@mshibuya [#2234](https://github.com/carrierwaveuploader/carrierwave/issues/2234))

## 1.2.0 - 2017-09-30

### Added

- Added Proc Support for Width and Height(@tomprats [#2169](https://github.com/carrierwaveuploader/carrierwave/pull/2169))

### Changed

- Decode unicode filenames from URL(@fedorkk [#2131](https://github.com/carrierwaveuploader/carrierwave/pull/2131))
- Change file size of error message to human size(@aki77 [#2199](https://github.com/carrierwaveuploader/carrierwave/pull/2199))

### Fixed

- Bundled en translation was not loaded by default, causing translation missing(@mshibuya [95ce39d3](https://github.com/carrierwaveuploader/carrierwave/commit/95ce39d3ec98bee9b2846b32fdcf093c78fa44fb))
- Remove potentially redundant HEAD request on checking fog file existence(@eritiro [#2140](https://github.com/carrierwaveuploader/carrierwave/pull/2140))
- Failing with uninitialized constant if uri is not loaded(@jasdeepsingh [#2223](https://github.com/carrierwaveuploader/carrierwave/pull/2223))
- RMagick cloud not process remotely stored files(@zog [#2185](https://github.com/carrierwaveuploader/carrierwave/pull/2185))
- Check if files are identical via FS rather than name before move(@riffraff [#2191](https://github.com/carrierwaveuploader/carrierwave/pull/2191))
- Regexp `extension_whitelist` is also case-insensitive now(@vmdhoke [#2201](https://github.com/carrierwaveuploader/carrierwave/pull/2201))
- Use `__send__` instead of `send` (@dminuoso [#2178](https://github.com/carrierwaveuploader/carrierwave/pull/2178))

## 1.1.0 - 2017-04-30

### Added

- Rails 5.1 compatibility(@paulsturgess [#2130](https://github.com/carrierwaveuploader/carrierwave/pull/2130), [#2133](https://github.com/carrierwaveuploader/carrierwave/pull/2133))
- Support for `process` callback(@cfcosta [#2045](https://github.com/carrierwaveuploader/carrierwave/pull/2045))
- S3 Transfer Acceleration support(@krekoten [#2108](https://github.com/carrierwaveuploader/carrierwave/pull/2108))
- Allow non-argument options to be passed in mini magick combine_options(@krismartin [#2097](https://github.com/carrierwaveuploader/carrierwave/pull/2097))

### Fixed

- Stop falling back to en locale when I18n is missing(@kryzhovnik [#2083](https://github.com/carrierwaveuploader/carrierwave/pull/2083))
- Allow nagative timestamp in cache id(@NickOttrando [#2092](https://github.com/carrierwaveuploader/carrierwave/pull/2092))
- Avoid calling `file.url` twice(@lukeasrodgers [#2078](https://github.com/carrierwaveuploader/carrierwave/pull/2078))
- Content Type being reset when moving cached file(@dweinand [#2117](https://github.com/carrierwaveuploader/carrierwave/pull/2117))

## 1.0.0 - 2016-12-24

_No changes._

## 1.0.0.rc - 2016-10-30

### Added

- Ability to set custom request headers on downloading remote URL(@mendab1e [#2006](https://github.com/carrierwaveuploader/carrierwave/pull/2006))

### Changed

- Re-enable `public_url` optimization for Google Cloud Storage(@nikz [#2039](https://github.com/carrierwaveuploader/carrierwave/pull/2039))

### Fixed

- Fix `clean_cache!` deleting unexpired files due to RegExp mismatch(@t-oginogin [#2036](https://github.com/carrierwaveuploader/carrierwave/pull/2036))

## 1.0.0.beta - 2016-09-08

### Added

- Rails 5 support (@mshibuya)
- Add `#width` and `#height` methods to the RMagick processor (@mehlah [#1805](https://github.com/carrierwaveuploader/carrierwave/pull/1805))
- Add a test matcher for the format (@yanivpr [#1758](https://github.com/carrierwaveuploader/carrierwave/pull/1758))
- Support of MiniMagick's Combine options (@bernabas [#1754](https://github.com/carrierwaveuploader/carrierwave/pull/1754))
- Validate with the actual content-type of files (@eavgerinos)
- Support for multiple file uploads with `mount_uploaders` method (@jnicklas and @lisarutan [#1481](https://github.com/carrierwaveuploader/carrierwave/pull/1481))
- Add a `cache_only` configuration option, useful for testing (@jeffkreeftmeijer [#1456](https://github.com/carrierwaveuploader/carrierwave/pull/1456))
- Add `#width` and `#height` methods to MiniMagick processor (@ShivaVS [#1405](https://github.com/carrierwaveuploader/carrierwave/pull/1405))
- Support for jRuby (@lephyrius [#1377](https://github.com/carrierwaveuploader/carrierwave/pull/1377))
- Make cache storage configurable (@mshibuya [#1312](https://github.com/carrierwaveuploader/carrierwave/pull/1312))
- Errors on file size (@gautampunhani [#1026](https://github.com/carrierwaveuploader/carrierwave/pull/1026))

### Changed

- Blank uploaders are now memoized on the model instance (@DarthSim [#1860](https://github.com/carrierwaveuploader/carrierwave/pull/1860))
- `#content_type_whitelist` and `extension_whitelist` now takes either a string, a regexp, or an array of values (same thing for blacklists) (@mehlah [#1825](https://github.com/carrierwaveuploader/carrierwave/pull/1825))
- [BREAKING CHANGE] Rename `extension_white_list` ~> `extension_whitelist` (@mehlah [#1819](https://github.com/carrierwaveuploader/carrierwave/pull/1819))
- [BREAKING CHANGE] Rename `extension_black_list` ~> `extension_blacklist` (@mehlah [#1819](https://github.com/carrierwaveuploader/carrierwave/pull/1819))
- [BREAKING CHANGE] Rename i18n keys `extension_black_list_error` ~> `extension_blacklist_error` and `extension_white_list_error` ~> `extension_whitelist_error` (@mehlah)
- Accept an array of strings or regexps to white/blacklist content types (@mehlah [#1816](https://github.com/carrierwaveuploader/carrierwave/pull/1816))
- Add counter to cache_id (@thomasfedb [#1797](https://github.com/carrierwaveuploader/carrierwave/pull/1797))
- [BREAKING CHANGE] Allow non-ASCII filename by default (@shuhei [#1772](https://github.com/carrierwaveuploader/carrierwave/pull/1772))
- [BREAKING CHANGE] `to_json` behavior changed when serializing an uploader (@jnicklas and @lisarutan [#1481](https://github.com/carrierwaveuploader/carrierwave/pull/1481))
- Better error when the configured storage is unknown (@st0012 [#1779](https://github.com/carrierwaveuploader/carrierwave/pull/1779))
- Allow to pass additionnal options to Rackspace `authenticated_url` (@duhast [#1722](https://github.com/carrierwaveuploader/carrierwave/pull/1722))
- Reduced memory footprint (@schneems [#1652](https://github.com/carrierwaveuploader/carrierwave/pull/1652), @simonprev [#1706](https://github.com/carrierwaveuploader/carrierwave/pull/1706))
- Improve Fog Loading (@plribeiro3000 [#1620](https://github.com/carrierwaveuploader/carrierwave/pull/1620), @eavgerinos)
- All locales from `config.i18n.available_locales` are added to load_path (@printercu [#1521](https://github.com/carrierwaveuploader/carrierwave/pull/1521))
- Do not display RMagick exception in I18n message (manuelpradal [#1361](https://github.com/carrierwaveuploader/carrierwave/pull/1361))
- [BREAKING CHANGE] `#default_url` now accepts the same args passed to `#url` (@shekibobo [#1347](https://github.com/carrierwaveuploader/carrierwave/pull/1347))

### Removed

- All locale files other than `en` are now in [carrierwave-i18n](https://github.com/carrierwaveuploader/carrierwave-i18n) (@mehlah [#1848](https://github.com/carrierwaveuploader/carrierwave/pull/1848))
- Remove `CarrierWave::MagicMimeTypes` processor module (@mehlah [#1816](https://github.com/carrierwaveuploader/carrierwave/pull/1816))
- Remove dependency on `ruby-filemagic` in white/blacklist content types (@mehlah [#1816](https://github.com/carrierwaveuploader/carrierwave/pull/1816))
- Remove `CarrierWave::MimeTypes` processor module (@mehlah [#1813](https://github.com/carrierwaveuploader/carrierwave/pull/1813))
- Remove support for Rails 3.2 and Ruby 1.8/1.9 (@bensie [2517d668](https://github.com/carrierwaveuploader/carrierwave/commit/2517d66809472fca9b1d5638eeeb515b351a8602))

### Fixed

- Don't raise an error when content_type is called on a deleted file (@jvenezia [#1915](https://github.com/carrierwaveuploader/carrierwave/pull/1915))
- #remove_previous fails to detect equality when mount_on option is set (@mshibuya [44cfb7c0](https://github.com/carrierwaveuploader/carrierwave/commit/44cfb7c01c22e0168d362001a7bb3c528c805315))
- Fix `Mounter.blank?` method (@Bonias [#1746](https://github.com/carrierwaveuploader/carrierwave/pull/1746))
- Reset `remove_#{column}` after invoking `remove_#{column}` (@eavgerinos [#1668](https://github.com/carrierwaveuploader/carrierwave/pull/1668))
- Change Google's url to the `public_url` (@m7moud [#1683](https://github.com/carrierwaveuploader/carrierwave/pull/1683))
- Do not write to `ActiveModel::Dirty` changes when assigning something blank to a mounter that was originally blank (@eavgerinos [#1635](https://github.com/carrierwaveuploader/carrierwave/pull/1635))
- Various grammar and typos fixes to error messages translations
- Don't error when size is called on a deleted file (@danielevans [#1561](https://github.com/carrierwaveuploader/carrierwave/pull/1561))
- Flush mounters on `#dup` of active record model (@danielevans [#1544](https://github.com/carrierwaveuploader/carrierwave/pull/1544))
- `Fog::File.read` returns its contents after upload instead of "closed stream" error (@stormsilver [#1517](https://github.com/carrierwaveuploader/carrierwave/pull/1517))
- Don't read file twice when calling `sanitized_file` or `cache!` (@felixbuenemann [#1476](https://github.com/carrierwaveuploader/carrierwave/pull/1476))
- Change image extension when converting formats (@nashby [#1446](https://github.com/carrierwaveuploader/carrierwave/pull/1446))
- Fix file delete being called twice on remove (@adamcrown [#1441](https://github.com/carrierwaveuploader/carrierwave/pull/1441))
- RSpec 3 support (@randoum [#1421](https://github.com/carrierwaveuploader/carrierwave/pull/1421), @akiomik [#1370](https://github.com/carrierwaveuploader/carrierwave/pull/1370))
- MiniMagick convert to a format all the pages by default and accept an optional page number parameter to convert specific pages (@harikrishnan83 [#1408](https://github.com/carrierwaveuploader/carrierwave/pull/1408))
- Fix cache workfile collision between versions (@jvdp [#1399](https://github.com/carrierwaveuploader/carrierwave/pull/1399))
- Reset mounter cache on record reload (@semenyukdmitriy [#1383](https://github.com/carrierwaveuploader/carrierwave/pull/1383))
- Retrieve only active versions of files (@filipegiusti [#1351](https://github.com/carrierwaveuploader/carrierwave/pull/1351))
- Fix default gravity in MiniMagick `resize_and_pad` (@abevoelker [#1358](https://github.com/carrierwaveuploader/carrierwave/pull/1358))
- Skip loading RMagick if already loaded (@mshibuya [#1346](https://github.com/carrierwaveuploader/carrierwave/pull/1346))
- Make the `#remove_#{column}` accessor set the mounted column as changed (@nikz [#1326](https://github.com/carrierwaveuploader/carrierwave/pull/1326))
- Tempfile and @content_type assignment (@bensie [#1487](https://github.com/carrierwaveuploader/carrierwave/issues/1487))

## 0.11.0 - 2016-03-29

### Added

### Changed

- `cache_id` is now less collision-prone thanks to a counter (@stillwaiting and @mtsmfm [#1866](https://github.com/carrierwaveuploader/carrierwave/pull/1866))

### Removed

### Fixed

- Fix require RMagick deprecation warning (@thomasfedb and @bensie [#1788](https://github.com/carrierwaveuploader/carrierwave/pull/1788))

## 0.10.0 - 2014-02-26

Please check [0.10-stable] for previous changes.

[0.10-stable]: https://github.com/carrierwaveuploader/carrierwave/blob/0.10-stable/History.txt
