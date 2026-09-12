# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 4.0.0.beta - 2026-09-07

### Added
* Add the `metadata_column` option to record what was stored, so that which versions were created no longer has to be decided again on retrieval (@mshibuya [ccac080](https://github.com/carrierwaveuploader/carrierwave/commit/ccac0800186a39d2e69e2f23c3383596681cb980), [#2148](https://github.com/carrierwaveuploader/carrierwave/issues/2148), [#1926](https://github.com/carrierwaveuploader/carrierwave/issues/1926))
* Add `#exists?` to ask the storage whether the file is actually there (@mshibuya [f635d88](https://github.com/carrierwaveuploader/carrierwave/commit/f635d88b9debeda27b25148856ca5e0faa186d17), [#1926](https://github.com/carrierwaveuploader/carrierwave/issues/1926))
* Make the downloader accept URLs as pasted by end users, stripping surrounding whitespace and embedded newlines and supplying a missing scheme (@mshibuya [c2a182e](https://github.com/carrierwaveuploader/carrierwave/commit/c2a182ef8c414eb43cca553ec06380075ea18a48))
* Support test matchers with only Vips (@gaffneyc [#2767](https://github.com/carrierwaveuploader/carrierwave/pull/2767))

### Changed
* [BREAKING CHANGE] Stop asking the storage whether the file is there in `#blank?` and `#present?`, which now only tell whether a file is assigned (@mshibuya [f635d88](https://github.com/carrierwaveuploader/carrierwave/commit/f635d88b9debeda27b25148856ca5e0faa186d17), [#2802](https://github.com/carrierwaveuploader/carrierwave/issues/2802), [#2776](https://github.com/carrierwaveuploader/carrierwave/issues/2776), [#2784](https://github.com/carrierwaveuploader/carrierwave/issues/2784))
* [BREAKING CHANGE] Stop percent-decoding the URL on download, keeping `%2F` and `/`, `%2B` and `+` distinct (@mshibuya [c2a182e](https://github.com/carrierwaveuploader/carrierwave/commit/c2a182ef8c414eb43cca553ec06380075ea18a48), [#858](https://github.com/carrierwaveuploader/carrierwave/issues/858), [#2505](https://github.com/carrierwaveuploader/carrierwave/issues/2505), [#2590](https://github.com/carrierwaveuploader/carrierwave/issues/2590), [#2800](https://github.com/carrierwaveuploader/carrierwave/issues/2800), [#2808](https://github.com/carrierwaveuploader/carrierwave/pull/2808))
* [BREAKING CHANGE] Decode the filename taken from a URL with URI semantics instead of form encoding, so a literal `+` no longer becomes a space (@mshibuya [c2a182e](https://github.com/carrierwaveuploader/carrierwave/commit/c2a182ef8c414eb43cca553ec06380075ea18a48))
* [BREAKING CHANGE] Refuse `process convert: format` with `:if`/`:unless`, as the resulting file extension cannot be worked out again on retrieval (@mshibuya [532da35](https://github.com/carrierwaveuploader/carrierwave/commit/532da3579bf67ff8f531c4f820e1dad2793adbd7), [#2723](https://github.com/carrierwaveuploader/carrierwave/issues/2723))
* Defer uploading a cached file to the remote cache storage until it's needed beyond the current request (@mshibuya [6f5d6b8](https://github.com/carrierwaveuploader/carrierwave/commit/6f5d6b80a99ab119000391a2cce3be76dbc7336f), [#2605](https://github.com/carrierwaveuploader/carrierwave/issues/2605))
* Defer evaluating the `:if`/`:unless` condition of versions until a version is accessed (@mshibuya [556a370](https://github.com/carrierwaveuploader/carrierwave/commit/556a370c7e5aa2a10b4e3258cd16016452ebb302), [#2461](https://github.com/carrierwaveuploader/carrierwave/issues/2461), [#2132](https://github.com/carrierwaveuploader/carrierwave/issues/2132), [#2669](https://github.com/carrierwaveuploader/carrierwave/pull/2669))
* Raise `ProcessingError` when all frames are filtered out in `#manipulate!` (@y-yagi [#2817](https://github.com/carrierwaveuploader/carrierwave/pull/2817))

### Removed
* Drop support for Ruby < 2.7 and Rails 6.x (@mshibuya [3ec4215](https://github.com/carrierwaveuploader/carrierwave/commit/3ec4215627a49fdc60d7c18834de3990625f7db1))

### Fixed
* Fix a file being stored under a name which doesn't follow from the identifier, leaving it where a later request could never find it. Storing is now refused instead (@mshibuya [532da35](https://github.com/carrierwaveuploader/carrierwave/commit/532da3579bf67ff8f531c4f820e1dad2793adbd7))
* Fix a race condition in `Builder#build`, where a thread could observe a version class before its options were set (@fwitzke [#2799](https://github.com/carrierwaveuploader/carrierwave/pull/2799))
* Fix the remote storage being asked again on every access when the file is not there (@mshibuya [f635d88](https://github.com/carrierwaveuploader/carrierwave/commit/f635d88b9debeda27b25148856ca5e0faa186d17), [#2698](https://github.com/carrierwaveuploader/carrierwave/pull/2698), [#2793](https://github.com/carrierwaveuploader/carrierwave/pull/2793))
* Fix `NoMethodError` on `#size` when the remote storage reports no content length (@mshibuya [f635d88](https://github.com/carrierwaveuploader/carrierwave/commit/f635d88b9debeda27b25148856ca5e0faa186d17), [#2787](https://github.com/carrierwaveuploader/carrierwave/issues/2787))
* Fix `#process_uri` being called twice on every download attempt (@mshibuya [c2a182e](https://github.com/carrierwaveuploader/carrierwave/commit/c2a182ef8c414eb43cca553ec06380075ea18a48))

Please check [3.x-stable](https://github.com/carrierwaveuploader/carrierwave/blob/3.x-stable/CHANGELOG.md) for previous changes.
