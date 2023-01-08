# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 3.0.0.beta - 2022-11-19
### Added
* Add basename and fix extension value for fog file (@leductienttkt [#2587](https://github.com/carrierwaveuploader/carrierwave/pull/2587))
* Allow uploaders to accept unless conditions (@Vpatel1093 [#2588](https://github.com/carrierwaveuploader/carrierwave/pull/2588))
* Add retry option to download from remote url (@tashirosota [#2577](https://github.com/carrierwaveuploader/carrierwave/pull/2577))

### Deprecated
* #denylist was deprecated to prefer explicitly opting-in (@mshibuya [7a40ef7](https://github.com/carrierwaveuploader/carrierwave/commit/7a40ef7c4d5f3033f0f8401323f80bde14ca72b9), [#2536](https://github.com/carrierwaveuploader/carrierwave/issues/2536))

### Changed
* Completely migrate to allowlist/denylist terminology (@mshibuya [7a40ef7](https://github.com/carrierwaveuploader/carrierwave/commit/7a40ef7c4d5f3033f0f8401323f80bde14ca72b9), [#2536](https://github.com/carrierwaveuploader/carrierwave/issues/2536))
* Remove implementation-dependent information from an error message (@akihikodaki [#2499](https://github.com/carrierwaveuploader/carrierwave/pull/2499))
* Replace mini_mime with marcel (@pjmartorell [#2552](https://github.com/carrierwaveuploader/carrierwave/pull/2552))

### Removed
* Drop support for Ruby < 2.5 and Rails 5.x (@mshibuya [229594f](https://github.com/carrierwaveuploader/carrierwave/commit/229594fb2ac7cfa59586162c0b3fc3d0b5bab978))
* Remove support for Merb (@seuros [#2566](https://github.com/carrierwaveuploader/carrierwave/pull/2566))

### Fixed
* Add Workaround for 'undefined method closed?' error caused by ssrf_filter 1.1 (@mshibuya [65bf0d9](https://github.com/carrierwaveuploader/carrierwave/commit/65bf0d94759f7d522a36698d4b81e3635b8ca572), [#2628](https://github.com/carrierwaveuploader/carrierwave/issues/2628))
* Fix Ruby 2.7 keyword argument warning in uploader process (@nachiket87 [#2636](https://github.com/carrierwaveuploader/carrierwave/pull/2636), [#2635](https://github.com/carrierwaveuploader/carrierwave/issues/2635))
* Raise DownloadError when no content is returned (@BrianHawley [#2633](https://github.com/carrierwaveuploader/carrierwave/pull/2633), [#2632](https://github.com/carrierwaveuploader/carrierwave/issues/2632))
* Add workaround for the API change in ssrf_filter 1.1 (@BrianHawley [#2629](https://github.com/carrierwaveuploader/carrierwave/pull/2629), [#2625](https://github.com/carrierwaveuploader/carrierwave/issues/2625))
* Fix Content-Type not being copied when using fog-google (@smnscp [#2614](https://github.com/carrierwaveuploader/carrierwave/pull/2614))
* Fix failing to save after limiting the columns with ActiveRecord's #select (@wonda-tea-coffee [#2613](https://github.com/carrierwaveuploader/carrierwave/pull/2613), [#2608](https://github.com/carrierwaveuploader/carrierwave/issues/2608))
* Fix content type detection for JSON files (@smnscp [#2618](https://github.com/carrierwaveuploader/carrierwave/pull/2618))
* Remove invalid byte sequences from the sanitized filename (@alexdunae [#2606](https://github.com/carrierwaveuploader/carrierwave/pull/2606))
* Fix issue with copying a fog file larger than 5GB (@slonopotamus [#2583](https://github.com/carrierwaveuploader/carrierwave/pull/2583))
* Stop closing StringIO-based file after CarrierWave::SanitizedFile#read (@aleksandrs-ledovskis [#2571](https://github.com/carrierwaveuploader/carrierwave/pull/2571))
* Remove uploaded files when transaction is rolled back (@fsateler [#2546](https://github.com/carrierwaveuploader/carrierwave/pull/2546))

Please check [2.x-stable](https://github.com/carrierwaveuploader/carrierwave/blob/2.x-stable/CHANGELOG.md) for previous changes.
