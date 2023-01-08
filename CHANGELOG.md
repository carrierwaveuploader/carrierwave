# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 2.2.3 - 2022-11-21
### Fixed
* Add workaround for 'undefined method closed?' error caused by ssrf_filter 1.1 (@mshibuya [c74579d](https://github.com/carrierwaveuploader/carrierwave/commit/c74579d382ad124193e80cc5af71824a23de57e6), [#2628](https://github.com/carrierwaveuploader/carrierwave/issues/2628))
* Add workaround for the API change in ssrf_filter 1.1 (@BrianHawley [#2629](https://github.com/carrierwaveuploader/carrierwave/pull/2629), [#2625](https://github.com/carrierwaveuploader/carrierwave/issues/2625))

## 2.2.2 - 2021-05-28
### Fixed
* Fix `no implicit conversion of CSV into String` error when parsing a CSV object (@pjmartorell [#2562](https://github.com/carrierwaveuploader/carrierwave/pull/2562), [#2559](https://github.com/carrierwaveuploader/carrierwave/issues/2559))

## 2.2.1 - 2021-03-30
### Changed
* Replace mimemagic with marcel due to licensing concern (@pjmartorell [#2551](https://github.com/carrierwaveuploader/carrierwave/pull/2551), [#2548](https://github.com/carrierwaveuploader/carrierwave/issues/2548))

### Fixed
* Fog storage's #clean_cache! breaks when non-cache objects exist in cache_dir (@mshibuya [42c620a1](https://github.com/carrierwaveuploader/carrierwave/commit/42c620a1a19afa61e15e617faa7ce9cc89ec1863), [#2532](https://github.com/carrierwaveuploader/carrierwave/pull/2532))

## 2.2.0 - 2021-02-23
### Added
* libvips support through [ImageProcessing::Vips](https://github.com/janko/image_processing) and [ruby-vips](https://github.com/libvips/ruby-vips) (@rhymes [#2500](https://github.com/carrierwaveuploader/carrierwave/pull/2500), [e8421978](https://github.com/carrierwaveuploader/carrierwave/commit/e84219787aa1c95a55cbc78ad062b7539d8e5813), [4ae8dc64](https://github.com/carrierwaveuploader/carrierwave/commit/4ae8dc64ff0dcbcf66c6d79df90268d57438df55))
* Provide alternatives to whitelist/blacklist terminology as allowlist/denylist, while old ones are still available but deprecated (@grantbdev [#2442](https://github.com/carrierwaveuploader/carrierwave/pull/2442), [4c3cac75](https://github.com/carrierwaveuploader/carrierwave/commit/4c3cac75f3a473e941045c23ebb781f61af67d79), [#2491](https://github.com/carrierwaveuploader/carrierwave/issues/2491))
* Support for the latest version of RMagick (@mshibuya [88f24451](https://github.com/carrierwaveuploader/carrierwave/commit/88f24451352bda128825f857cde473107d98fca7))

### Deprecated
* `#(content_type|extension)_whitelist`, `#(content_type|extension)_blacklist` are deprecated. Use `#(content_type|extension)_allowlist` and `#(content_type|extension)_denylist` instead (@grantbdev [#2442](https://github.com/carrierwaveuploader/carrierwave/pull/2442), [4c3cac75](https://github.com/carrierwaveuploader/carrierwave/commit/4c3cac75f3a473e941045c23ebb781f61af67d79))

### Fixed
* Calculate Fog expiration taking DST into account (@mshibuya, [f90e14ca](https://github.com/carrierwaveuploader/carrierwave/commit/f90e14ca91892d677ee6ed42321a21a2fe98f360), [#2059](https://github.com/carrierwaveuploader/carrierwave/issues/2059))
* Set correct content type on copy of fog files (@ZuevEvgenii [#2503](https://github.com/carrierwaveuploader/carrierwave/pull/2503), [6682f7ac](https://github.com/carrierwaveuploader/carrierwave/commit/6682f7ac5dd480269448a614026a5f4524e61550), [#2487](https://github.com/carrierwaveuploader/carrierwave/issues/2487))
* Fix fog-google support to pass acl_header for public read if fog is public (@yosiat [#2525](https://github.com/carrierwaveuploader/carrierwave/pull/2525), [#2426](https://github.com/carrierwaveuploader/carrierwave/issues/2426))
* Fix various URL escape issues by escaping on URI parse error only (@mshibuya [3faf7491](https://github.com/carrierwaveuploader/carrierwave/commit/3faf7491e33bd10ae8b3e0010501fc96a76c21c3), [#2457](https://github.com/carrierwaveuploader/carrierwave/pull/2457), [#2473](https://github.com/carrierwaveuploader/carrierwave/pull/2473))
* Fix instance variables `@versions_to_*` not initialized warning (@mshibuya [c10b82ed](https://github.com/carrierwaveuploader/carrierwave/commit/c10b82ed2f7b20cb58772281e3510dc70c410732), [#2493](https://github.com/carrierwaveuploader/carrierwave/issues/2493))
* Fix `SanitizedFile#move_to` wrongly detects content_type based on the path before move (@mshibuya [a42e1b4c](https://github.com/carrierwaveuploader/carrierwave/commit/a42e1b4c504c6f69c4c4c7802ebd45523134c42e), [#2495](https://github.com/carrierwaveuploader/carrierwave/issues/2495))
* Fix returning invalid content type on text files (@inkstak [#2474](https://github.com/carrierwaveuploader/carrierwave/pull/2474), [#2424](https://github.com/carrierwaveuploader/carrierwave/issues/2424))
* Skip content type and extension filters where possible (@alexpooley [#2464](https://github.com/carrierwaveuploader/carrierwave/pull/2464))
* Fix file's `#url` being called twice, which might be costly for non-local files (@skyeagle [#2519](https://github.com/carrierwaveuploader/carrierwave/pull/2519))
* Fix mime type detection failing with types which contain `+` symbol, such as `image/svg+xml` (@sylvainbx [#2489](https://github.com/carrierwaveuploader/carrierwave/pull/2489))
* Fix `#cached?` to return boolean instead of `@cache_id` value (@kmiyake [#2510](https://github.com/carrierwaveuploader/carrierwave/pull/2510))
* Fix mime type detection for MS Office files (@anthonypenner [#2447](https://github.com/carrierwaveuploader/carrierwave/pull/2447))

### Security
* Fix Code Injection vulnerability in CarrierWave::RMagick (@mshibuya [387116f5](https://github.com/carrierwaveuploader/carrierwave/commit/387116f5c72efa42bc3938d946b4c8d2f22181b7), [GHSA-cf3w-g86h-35x4](https://github.com/carrierwaveuploader/carrierwave/security/advisories/GHSA-cf3w-g86h-35x4))
* Fix SSRF vulnerability in the remote file download feature (@mshibuya [012702eb](https://github.com/carrierwaveuploader/carrierwave/commit/012702eb3ba1663452aa025831caa304d1a665c0), [GHSA-fwcm-636p-68r5](https://github.com/carrierwaveuploader/carrierwave/security/advisories/GHSA-fwcm-636p-68r5))

## 2.1.1 - 2021-02-08
### Security
* Fix Code Injection vulnerability in CarrierWave::RMagick (@mshibuya [15bcf8d8](https://github.com/carrierwaveuploader/carrierwave/commit/15bcf8d84f5cf56e9fe5bcdcc2074aafbd45630b), [GHSA-cf3w-g86h-35x4](https://github.com/carrierwaveuploader/carrierwave/security/advisories/GHSA-cf3w-g86h-35x4))
* Fix SSRF vulnerability in the remote file download feature (@mshibuya [e0f79e36](https://github.com/carrierwaveuploader/carrierwave/commit/e0f79e3678f2b58e98bc72495db1033646d14cd1), [GHSA-fwcm-636p-68r5](https://github.com/carrierwaveuploader/carrierwave/security/advisories/GHSA-fwcm-636p-68r5))

## 2.1.0 - 2020-02-16
### Added
* Support authenticated_url for Blackblaze provider(@kevivmatrix [#2444](https://github.com/carrierwaveuploader/carrierwave/pull/2444))

### Fixed
* Fix Ruby 2.7 deprecations(@mshibuya [9a37fc9e](https://github.com/carrierwaveuploader/carrierwave/commit/9a37fc9e7ce2937c66d5419ce1943ed114385beb))
* Fix S3 path-style URL for host with dots for buckets that are placed in other regions than us-east-1(@Bonias [#2439](https://github.com/carrierwaveuploader/carrierwave/pull/2439))
* Make MiniMagick::Image constant absolute to prevent misleading 'uninitialized constant' error(@p8 [#2437](https://github.com/carrierwaveuploader/carrierwave/pull/2437))

## 2.0.2 - 2019-09-28
### Fixed
* Fix download causing nil error if the file has empty filename(@fukayatsu [#2419](https://github.com/carrierwaveuploader/carrierwave/pull/2419), [#2411](https://github.com/carrierwaveuploader/carrierwave/issues/2411))

## 2.0.1 - 2019-08-31
### Fixed
* Fix `#{column}_cache` unintentionally removing files on assigning empty string(@mshibuya [22e8005e](https://github.com/carrierwaveuploader/carrierwave/commit/22e8005e44751fbce9f088497853aa60b6c89fcc), [#2412](https://github.com/carrierwaveuploader/carrierwave/issues/2412))

## 2.0.0 - 2019-08-18

_No changes._

## 2.0.0.rc - 2019-06-23
### Added
* Append, reorder, and remove-single-file feature for multiple file uploader(@mshibuya [#2401](https://github.com/carrierwaveuploader/carrierwave/pull/2401))
* Allow retrieval of uploader index within uploaders(@mshibuya [#1771](https://github.com/carrierwaveuploader/carrierwave/issues/1771))
* Add ability to customize downloaders(@mshibuya [#1636](https://github.com/carrierwaveuploader/carrierwave/issues/1636))
* Support internationalized domain names for downloader(@mshibuya [#2086](https://github.com/carrierwaveuploader/carrierwave/issues/2086))
* Support authenticated_url for Aliyun provider(@Nitrino [#2381](https://github.com/carrierwaveuploader/carrierwave/pull/2381))
* Support passing options to authenticated_url for OpenStack provider(@stanhu [#2377](https://github.com/carrierwaveuploader/carrierwave/pull/2377))
* Support authenticated_url for AzureRM provider(@Nitrino [#2375](https://github.com/carrierwaveuploader/carrierwave/pull/2375))
* Allow custom expires_at when building an authenticated_url(@stephankaag [#2397](https://github.com/carrierwaveuploader/carrierwave/pull/2397))

### Changed
* [BREAKING CHANGE] Use the storage given by `storage` configuration also for `cache_storage` unless explicitly specified(@mshibuya [629afecb](https://github.com/carrierwaveuploader/carrierwave/commit/629afecbaeccd2300e4660b78ee36bd95dd845c5))
* Improve Fog initialization(@mshibuya [#2395](https://github.com/carrierwaveuploader/carrierwave/issues/2395))
* [BREAKING CHANGE] Multiple file uploader now keeps successful files on update, only discarding failed ones(@mshibuya [7db9195d](https://github.com/carrierwaveuploader/carrierwave/commit/7db9195de3197fcecfb442caa434369fe0e37846))
* [BREAKING CHANGE] `#remote_#{column}_urls=` was changed to preserve precedent updates(@mshibuya [8f18a95b](https://github.com/carrierwaveuploader/carrierwave/commit/8f18a95b74517ba96f6c571401d537f048e36961))
* `#serializable_hash` now returns string for version keys(@schovi [#2246](https://github.com/carrierwaveuploader/carrierwave/pull/2246))
* Use the MimeMagic gem to inspect file headers for the mime type. This allows for mitigation of CVE-2016-3714, in combination with a `content_type_whitelist`(@locriani [#1934](https://github.com/carrierwaveuploader/carrierwave/pull/1934))
* Replace mime-types dependency with mini_mime to save memory(@bradleypriest [#2292](https://github.com/carrierwaveuploader/carrierwave/pull/2292))
* Delegate MiniMagick processing to ImageProcessing gem(@janko [#2298](https://github.com/carrierwaveuploader/carrierwave/pull/2298))
* Handle ActiveRecord transaction correctly, not storing or removing files on rollback(@skosh [#2209](https://github.com/carrierwaveuploader/carrierwave/pull/2209))

### Deprecated
* `fog_provider` configuration was deprecated and has no effect, just adding fog providers to `Gemfile` will load them(@mshibuya [ca201ee2](https://github.com/carrierwaveuploader/carrierwave/commit/ca201ee2ceebe2d916be3bc1396fe381cc93afd7))
* `CarrierWave::Uploader::Base#sanitized_file` was deprecated, use `#file` instead(@mshibuya [28190e99](https://github.com/carrierwaveuploader/carrierwave/commit/28190e99299a6131c0424a5d10205f471e39f3cd))

### Removed
* Remove support for Rails 4.x and Ruby 2.0/2.1 (@mshibuya [bada043f](https://github.com/carrierwaveuploader/carrierwave/commit/bada043f39801625d748b9a89ef475eff5c8bdd5))

### Fixed
* Fix deleting files twice when marked for removal(@mshibuya [67800fde](https://github.com/carrierwaveuploader/carrierwave/commit/67800fdeb796a7b2efe1192e06f619dcc3c64f05))
* Fix `uploader.cache!` loads entire contents of file into memory(@mshibuya [#2136](https://github.com/carrierwaveuploader/carrierwave/issues/2136))
* Do not trigger *_will_change! when file is not to be removed(@mshibuya [#2323](https://github.com/carrierwaveuploader/carrierwave/issues/2323))
* Allow deleting all files for multiple file upload(@mshibuya [#1990](https://github.com/carrierwaveuploader/carrierwave/issues/1990))
* Failing to retrieve unquoted filenames from Content-Disposition(@mshibuya [#2364](https://github.com/carrierwaveuploader/carrierwave/issues/2364))
* Fix `#clean_cache!` breaking with old format of cache id(@mshibuya [aab402fb](https://github.com/carrierwaveuploader/carrierwave/commit/aab402fb5232c0ebfe2584c22c3fb0161613dc33))
* Fix `#exists?` returning true after Fog file deletion(@mshibuya [#2387](https://github.com/carrierwaveuploader/carrierwave/issues/2387))
* Make `#identifier` available for a retrieved file(@mshibuya [#1581](https://github.com/carrierwaveuploader/carrierwave/issues/1581))
* Make cache id generation less predictable(@mshibuya [#2326](https://github.com/carrierwaveuploader/carrierwave/issues/2326))
* Uploaders not being cleared when `#reload` or `#initialize_dup` are overridden in model(@mshibuya [#2379](https://github.com/carrierwaveuploader/carrierwave/issues/2379))
* Fix `#content_type` returning false, instead of nil(@longkt90 [#2384](https://github.com/carrierwaveuploader/carrierwave/pull/2384))
* Preserve connection cache when eagar-loading fog(@dmitryshagin [#2383](https://github.com/carrierwaveuploader/carrierwave/pull/2383))
* `#recreate_versions!` ignored `:from_version` when versions to recreate are given(@hedgesky [#1879](https://github.com/carrierwaveuploader/carrierwave/pull/1879) [#1164](https://github.com/carrierwaveuploader/carrierwave/issues/1164))

Please check [1.x-stable](https://github.com/carrierwaveuploader/carrierwave/blob/1.x-stable/CHANGELOG.md) for previous changes.
