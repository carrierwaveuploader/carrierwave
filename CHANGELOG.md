# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 4.0.0.rc - 2026-10-12

### Added
* Support direct uploads with `#direct_upload`, where the client sends the file straight to the storage service and the bytes never pass through the application (@mshibuya [1677465](https://github.com/carrierwaveuploader/carrierwave/commit/1677465d2e2e9834afc4728cf35c2c18e8570db2))
* Support cache ids which were made outside CarrierWave, by overriding `#parse_cache_id` (@mshibuya [ed90d7f](https://github.com/carrierwaveuploader/carrierwave/commit/ed90d7f3aa205fe2e6ee875ba18141e28e72ee71))
* Support mounting a file which is already in the store with `#{column}_identifier=` and `#adopt!`, for when something other than CarrierWave put it there (@mshibuya [d12660d](https://github.com/carrierwaveuploader/carrierwave/commit/d12660df73e9ec68b734f0f6b7f7159a0b23dc77))
* Support customising how a download resolves and connects, such as preferring IPv4, with the `ssrf_filter_options` configuration passed to SsrfFilter (@kaibadash [#2813](https://github.com/carrierwaveuploader/carrierwave/pull/2813))
* Support storing to a bucket which has ACLs disabled, and setting the ACL apart from `fog_public`, with the `fog_acl` configuration (@stanhu [#2811](https://github.com/carrierwaveuploader/carrierwave/pull/2811))

### Deprecated
* Deprecate passing a block to `#convert`, `#resize_to_limit`, `#resize_to_fit`, `#resize_to_fill`, `#resize_and_pad` and `#crop` to receive a `MiniMagick::Image`. Use `#manipulate!` for a `MiniMagick::Image`, or `#minimagick!` for the ImageProcessing builder (@mshibuya [acc722d](https://github.com/carrierwaveuploader/carrierwave/commit/acc722d751a2b550b366107f2ad4dbe6f66abeef))

### Fixed
* Fix a refused file going unreported when the record is saved through an association, so that the save appeared to succeed without it (@mshibuya [c7cd6e5](https://github.com/carrierwaveuploader/carrierwave/commit/c7cd6e5b994e5e6d22985a8fad43a07f502da02b), [#2727](https://github.com/carrierwaveuploader/carrierwave/issues/2727))
* Fix assigning a refused file deleting the one which was already stored (@mshibuya [1cfb5f8](https://github.com/carrierwaveuploader/carrierwave/commit/1cfb5f856daae8eb86a1c51db512c61e1e333362))
* Fix an upload whose filename carries a NUL byte raising `ArgumentError` instead of being accepted (@mshibuya [246ff3b](https://github.com/carrierwaveuploader/carrierwave/commit/246ff3b24d67b9c1891f7b9e13c72a8e9d0eb649))
* Fix an upload whose filename is longer than the filesystem takes raising `Errno::ENAMETOOLONG`, which now fails validation instead (@mshibuya [c34c0d5](https://github.com/carrierwaveuploader/carrierwave/commit/c34c0d57a18f46eb3159b59f0df85660e36c798c))
* Fix caching a file which carries no name of its own, such as a bare `StringIO`, raising `TypeError` (@mshibuya [2b0a12e](https://github.com/carrierwaveuploader/carrierwave/commit/2b0a12ee58bd956267534f00617279722a99a2a8), [#1831](https://github.com/carrierwaveuploader/carrierwave/issues/1831))
* Fix `InvalidParameter` when caching or manipulating a version of a file which came from the store rather than the cache (@mshibuya, @SergeyProger [0d00f7e](https://github.com/carrierwaveuploader/carrierwave/commit/0d00f7ead938b9e3dbdcc67128c7dbe27af29d08), [#2798](https://github.com/carrierwaveuploader/carrierwave/issues/2798))
* Fix a file keeping its old extension after `#manipulate!` changed its format (@mshibuya [cd0686f](https://github.com/carrierwaveuploader/carrierwave/commit/cd0686f68072625d27c5697ca7e86394e76d1c1f), [#2714](https://github.com/carrierwaveuploader/carrierwave/issues/2714))
* Fix a cache name which is only a cache id, as a direct upload can leave behind, being taken for a directory instead of the file (@mshibuya [b9f8c62](https://github.com/carrierwaveuploader/carrierwave/commit/b9f8c62a053063181994063f3ed6fb28ac02e8cf))
* Fix an uploader which picks its storage per file caching somewhere other than where it stores (@mshibuya [81da3b8](https://github.com/carrierwaveuploader/carrierwave/commit/81da3b88c8b34b26d248a1a2f2f1ae0d5f0113ce))
* Fix obsolete warnings from `URI::RFC3986_PARSER#escape` and `#unescape` (@mshibuya [b3d77e6](https://github.com/carrierwaveuploader/carrierwave/commit/b3d77e6fa1192a99edc1eae170f701b6c708bf63), [#2796](https://github.com/carrierwaveuploader/carrierwave/issues/2796))
* Fix storing a Fog file to where it already is being refused by S3 (@mshibuya [229fdfc](https://github.com/carrierwaveuploader/carrierwave/commit/229fdfcda55e033989b4dec63f0f61e8a8b46341))
* Fix `clean_cached_files!` removing files outside the cache directory which merely look like a cache (@mshibuya [f4691e6](https://github.com/carrierwaveuploader/carrierwave/commit/f4691e6f9c76b583c0d0849d5169536b40395f7c))
* Fix the remove callbacks being run for a mounted column which had no file (@mshibuya [b038f12](https://github.com/carrierwaveuploader/carrierwave/commit/b038f126776cdaa35e2a612fd95c20a88bb9adcc))

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
