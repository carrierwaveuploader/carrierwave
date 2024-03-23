# Carrierwave History/Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 3.0.7 - 2024-03-23

### Security
* Fix Content-Type allowlist bypass vulnerability remained (@mshibuya [00676e2](https://github.com/carrierwaveuploader/carrierwave/commit/00676e23d7f4beac12beddee6f2486b686fb7e46), [GHSA-vfmv-jfc5-pjjw](https://github.com/carrierwaveuploader/carrierwave/security/advisories/GHSA-vfmv-jfc5-pjjw))

## 3.0.6 - 2024-03-09

### Fixed
* Fix #derived_versions and #active_sibling_versions returning an Array where Hash is expected (@mshibuya [46e4f20](https://github.com/carrierwaveuploader/carrierwave/commit/46e4f20f8f85f75043cec76aa1f331c55a3ba103))
* Fix incompatibility with Marcel 1.0.3 (@schinery [#2728](https://github.com/carrierwaveuploader/carrierwave/pull/2728), [#2729](https://github.com/carrierwaveuploader/carrierwave/issues/2729))
* Fix assigning a file with the same name not marking the column as changed (@mshibuya [4c65b39](https://github.com/carrierwaveuploader/carrierwave/commit/4c65b393cd85b66bc256d04363cf3e3a97c8fd64), [#2719](https://github.com/carrierwaveuploader/carrierwave/issues/2719))
* Fix failing to remove files with ActiveRecord 7.1 after_commit order change enabled (@mshibuya [63113e9](https://github.com/carrierwaveuploader/carrierwave/commit/63113e96dc172114cb92af239ba73e50ed8a72f2), [#2713](https://github.com/carrierwaveuploader/carrierwave/issues/2713))

## 3.0.5 - 2023-11-29

### Fixed
* Remove unnecessary if clause within #filename left in the uploader template (@rajyan [#2711](https://github.com/carrierwaveuploader/carrierwave/pull/2711))

### Security
* Fix Content-Type allowlist bypass vulnerability, possibly leading to XSS (@mshibuya [863d425](https://github.com/carrierwaveuploader/carrierwave/commit/863d425c76eba12c3294227b39018f6b2dccbbf3), [GHSA-gxhx-g4fq-49hj](https://github.com/carrierwaveuploader/carrierwave/security/advisories/GHSA-gxhx-g4fq-49hj))

## 3.0.4 - 2023-10-08

### Fixed
* Fix model's dirty state remaining after update (@rajyan [#2707](https://github.com/carrierwaveuploader/carrierwave/pull/2707), [#2702](https://github.com/carrierwaveuploader/carrierwave/issues/2702))
* Fix #dup modifying the original object (@rajyan [#2690](https://github.com/carrierwaveuploader/carrierwave/pull/2690), [#2706](https://github.com/carrierwaveuploader/carrierwave/pull/2706), [#2689](https://github.com/carrierwaveuploader/carrierwave/issues/2689), [#2700](https://github.com/carrierwaveuploader/carrierwave/issues/2700))
* Fix #dup not respecting the :mount_on option, causing MissingAttributeError (@marsz [#2691](https://github.com/carrierwaveuploader/carrierwave/pull/2691))

## 3.0.3 - 2023-08-21

### Fixed
* Fix #dup modifying the original object (@mshibuya [37f36f7](https://github.com/carrierwaveuploader/carrierwave/commit/37f36f7ccf035ffb19cbd3964928b3abf2d5e1b1), [#2687](https://github.com/carrierwaveuploader/carrierwave/issues/2687))
* Fix wrongly removing files on transaction rollback (@mshibuya, @rajyan [eb03fe1](https://github.com/carrierwaveuploader/carrierwave/commit/eb03fe124c3a7acf3ffc913c7d432208ba3aa7ca), [#2686](https://github.com/carrierwaveuploader/carrierwave/pull/2686), [#2685](https://github.com/carrierwaveuploader/carrierwave/issues/2685))

## 3.0.2 - 2023-08-01

### Fixed
* Fix deduplicated filename not being persisted (@mshibuya [#2679](https://github.com/carrierwaveuploader/carrierwave/pull/2679), [#2678](https://github.com/carrierwaveuploader/carrierwave/issues/2678), [#2677](https://github.com/carrierwaveuploader/carrierwave/pull/2677))

## 3.0.1 - 2023-07-22

### Fixed
* Fix not respecting the parent's #enable_processing value after reading its own (@mshibuya [2df0f53](https://github.com/carrierwaveuploader/carrierwave/commit/2df0f53f1d5fa30a198aa148ef33f1ab924404e4), [#2676](https://github.com/carrierwaveuploader/carrierwave/issues/2676))
* Fix NoMethodError when a record is rolled back (@y-yagi [#2674](https://github.com/carrierwaveuploader/carrierwave/pull/2674), [#2675](https://github.com/carrierwaveuploader/carrierwave/issues/2675))
* Fix filename suffix being removed due to unnecessary deduplication (@mshibuya [d68a111](https://github.com/carrierwaveuploader/carrierwave/commit/d68a1111cfae4309d703caa19d9c19226bc01686), [#2672](https://github.com/carrierwaveuploader/carrierwave/issues/2672))
* Fix #dup causing unintended name deduplication of copied files (@mshibuya [b732acd](https://github.com/carrierwaveuploader/carrierwave/commit/b732acd63209897e6375a3706330df2c38e3f327), [#2670](https://github.com/carrierwaveuploader/carrierwave/issues/2670))
* Fix initialization failing when active_support/core_ext is not loaded yet (@mshibuya [875d972](https://github.com/carrierwaveuploader/carrierwave/commit/875d972dc78b8416de7768457793baa4d6220a4f))

## 3.0.0 - 2023-07-02

_No changes._

## 3.0.0.rc - 2023-06-11
### Added
* Support adding suffix to filename on store when path collides with the existing ones (@mshibuya [07a5632](https://github.com/carrierwaveuploader/carrierwave/commit/07a5632a3f30ddcb21b10a75f003a7eaeaa072ad), [#1855](https://github.com/carrierwaveuploader/carrierwave/issues/1855))
* Add image dimension validation (@TsubasaYoshida [#2592](https://github.com/carrierwaveuploader/carrierwave/pull/2592), [3b1f8b4](https://github.com/carrierwaveuploader/carrierwave/commit/3b1f8b41f8c0896aa6ebe64bac23622c14a8b8d9))
* Provide validation error details via ActiveModel::Errors#details (@mshibuya [9013999](https://github.com/carrierwaveuploader/carrierwave/commit/90139995fc11978da909db71b1d43c0690c7c9d2), [#2150](https://github.com/carrierwaveuploader/carrierwave/issues/2150))
* Support clearing #remote_urls by assigning nil (@mshibuya [8307f93](https://github.com/carrierwaveuploader/carrierwave/commit/8307f93c29b833d34efaae63c33d36e737d94715), [#2067](https://github.com/carrierwaveuploader/carrierwave/issues/2067))
* Support configuration of download retry wait time (@tricknotes [#2646](https://github.com/carrierwaveuploader/carrierwave/pull/2646))
* Support for ActiveRecord::Base#dup (@mshibuya, @BrianHawley [19b33b8](https://github.com/carrierwaveuploader/carrierwave/commit/19b33b876cd58e7af28dc718fd4f47bb539b78f9), [#2645](https://github.com/carrierwaveuploader/carrierwave/pull/2645), [#1962](https://github.com/carrierwaveuploader/carrierwave/issues/1962))
* Add CarrierWave::Storage::Fog::File#to_file for interface consistency with SanitizedFile (@mshibuya [68ce83a](https://github.com/carrierwaveuploader/carrierwave/commit/68ce83a7b105d52c6af1b410727dd590c3960f7d), [#1960](https://github.com/carrierwaveuploader/carrierwave/issues/1960))
* Allow SanitizedFile to accept read with an optional length and output_buffer arguments (@mshibuya [9096459](https://github.com/carrierwaveuploader/carrierwave/commit/90964596aa3d0b7acea584012f0f5888d622ea1b), [#1959](https://github.com/carrierwaveuploader/carrierwave/issues/1959))

### Changed
* Stop relying on ActiveModel::Dirty change tracking for removal of unnecessary files (@mshibuya [aac25c1](https://github.com/carrierwaveuploader/carrierwave/commit/aac25c10af4218d6e1e70f90154b847b54ce0334))
* Create versions lazily to reflect subclass configurations properly (@mshibuya [1531a67](https://github.com/carrierwaveuploader/carrierwave/commit/1531a67366f0e25e3d298133a72c81b6c9c0dc83), [#1957](https://github.com/carrierwaveuploader/carrierwave/issues/1957), [#2619](https://github.com/carrierwaveuploader/carrierwave/issues/2619))
* [BREAKING CHANGE] Use the resulting file extension on changing format by :convert (@mshibuya [#2659](https://github.com/carrierwaveuploader/carrierwave/pull/2659), [#2125](https://github.com/carrierwaveuploader/carrierwave/issues/2125), [#2126](https://github.com/carrierwaveuploader/carrierwave/issues/2126), [#2254](https://github.com/carrierwaveuploader/carrierwave/issues/2254))
* Prioritize Magic-detected content type for spoof-tolerance (@mshibuya [a2ca59c](https://github.com/carrierwaveuploader/carrierwave/commit/a2ca59cbe67046ba7818c64849a9a4ffa90306db), [#2570](https://github.com/carrierwaveuploader/carrierwave/issues/2570))
* Handle assignments in an ActiveModel::Dirty-friendly way (@mshibuya [#2658](https://github.com/carrierwaveuploader/carrierwave/pull/2658), [#2404](https://github.com/carrierwaveuploader/carrierwave/issues/2404), [#2409](https://github.com/carrierwaveuploader/carrierwave/issues/2409), [#2468](https://github.com/carrierwaveuploader/carrierwave/issues/2468))
* Give a stable name to classes created by the mount_uploader block (@mshibuya [f5b09b8](https://github.com/carrierwaveuploader/carrierwave/commit/f5b09b844d99245a3b4d0ba01efd4972be4ee5be), [#2407](https://github.com/carrierwaveuploader/carrierwave/issues/2407), [#2471](https://github.com/carrierwaveuploader/carrierwave/issues/2471))
* Give a stable name to version classes (@mshibuya [a9de756](https://github.com/carrierwaveuploader/carrierwave/commit/a9de7565eabb4cdca05bb090cdf797eb1720c09c), [#2407](https://github.com/carrierwaveuploader/carrierwave/issues/2407), [#2471](https://github.com/carrierwaveuploader/carrierwave/issues/2471))

### Fixed
* Fix CarrierWave::Storage::Fog::File#read breaking when the file doesn't exist (@mshibuya [246eb01](https://github.com/carrierwaveuploader/carrierwave/commit/246eb012e15a75f7621bf9933f90a0f4742bd6e8), [#2524](https://github.com/carrierwaveuploader/carrierwave/issues/2524))
* Fix to preserve the original URI as much as possible on download (@mshibuya [2f3afaf](https://github.com/carrierwaveuploader/carrierwave/commit/2f3afafb738ae848a8a2d164780571cf9a7eb6ce), [#2631](https://github.com/carrierwaveuploader/carrierwave/issues/2631))
* Fix not to invoke content type detection on #copy_to as it's costly (@mshibuya [6c6e2dc](https://github.com/carrierwaveuploader/carrierwave/commit/6c6e2dc9cf7747c0c1571d315473b246ef582e1f), [#2465](https://github.com/carrierwaveuploader/carrierwave/issues/2465))
* Fix calling #=~ on non-String breaking in Ruby 3.2 (@aubinlrx [#2653](https://github.com/carrierwaveuploader/carrierwave/pull/2653), [fd03ddd](https://github.com/carrierwaveuploader/carrierwave/commit/fd03dddef55025cab83936fc2957e3c8c58772ae))
* Fix #clean_cache! to respect the uploader's root, not the global one (@sawasaki-narumi [#2652](https://github.com/carrierwaveuploader/carrierwave/pull/2652), [3cb9992](https://github.com/carrierwaveuploader/carrierwave/commit/3cb9992cc5fb8b113fe5b050651361f35d94adb4), [#2113](https://github.com/carrierwaveuploader/carrierwave/issues/2113))
* Fix to use helper method #fog_provider instead of checking #fog_credentials (@joshuamsager [#2660](https://github.com/carrierwaveuploader/carrierwave/pull/2660))
* Fix being unable to delete a file by assigning nil (@mshibuya [f8ea354](https://github.com/carrierwaveuploader/carrierwave/commit/f8ea35445e51c438b8cc8baf3e50079b5d423e34), [#2654](https://github.com/carrierwaveuploader/carrierwave/issues/2654), [#2613](https://github.com/carrierwaveuploader/carrierwave/pull/2613))
* Fix to raise exception when ImageMagick is not installed (@mshibuya [d90c399](https://github.com/carrierwaveuploader/carrierwave/commit/d90c399a6d2338203b1382f4ac4269863444d60d), [#2060](https://github.com/carrierwaveuploader/carrierwave/issues/2060))
* Fix to remove unnecessary floodfill in CarrierWave::RMagick#resize_and_pad (@mshibuya [f34a9bd](https://github.com/carrierwaveuploader/carrierwave/commit/f34a9bd26ed3e1006033a783c2ae8d86369993f6))
* Fix `#{column}_cache=` fails to be stored when set as a nested attribute (@mshibuya [e84d11e](https://github.com/carrierwaveuploader/carrierwave/commit/e84d11ec508d286ebab28195da815816abc62e41), [#2206](https://github.com/carrierwaveuploader/carrierwave/issues/2206))
* Fix to use AWS S3 regional endpoints when using virtual-hosted style (@mshibuya [8dace34](https://github.com/carrierwaveuploader/carrierwave/commit/8dace3456b5d1e0c3212ed1dc6c8b47dfd63b8ff), [#2523](https://github.com/carrierwaveuploader/carrierwave/issues/2523))
* Fix to respect condition on processing a derived version (@mshibuya [1fecddc](https://github.com/carrierwaveuploader/carrierwave/commit/1fecddc8ffe43426e9b5044dedfa7ac0b091cad8), [#2516](https://github.com/carrierwaveuploader/carrierwave/issues/2516))
* Fix #recreate_versions! affecting the original file (@mshibuya [a67bfb6](https://github.com/carrierwaveuploader/carrierwave/commit/a67bfb696dcba14c7cdfa2c1b5481f04d3ef8dae), [5f00715](https://github.com/carrierwaveuploader/carrierwave/commit/5f00715747d44dd7f57ee990a6b471ed786ac764), [#2480](https://github.com/carrierwaveuploader/carrierwave/issues/2480), [#2655](https://github.com/carrierwaveuploader/carrierwave/issues/2655))
* Fix `remove_#{column}!` doesn't remove the file immediately (@mshibuya [b719fb3](https://github.com/carrierwaveuploader/carrierwave/commit/b719fb373c48f23e874dfa1a333a954c01967fc1), [#2540](https://github.com/carrierwaveuploader/carrierwave/issues/2540))
* Fix column value populated without a file when using filename override (@mshibuya [f1eff6e](https://github.com/carrierwaveuploader/carrierwave/commit/f1eff6e212fb0c374c9235968bfc4e7580bf1e2a), [#2284](https://github.com/carrierwaveuploader/carrierwave/issues/2284))
* Fix boolean configurations couldn't be set to false on a per-uploader basis (@megane42 [#2642](https://github.com/carrierwaveuploader/carrierwave/pull/2642))
* Fix #clean_cache! breaking with directories that doesn't conform to CarrierWave's cache_id format (@BrianHawley [#2641](https://github.com/carrierwaveuploader/carrierwave/pull/2641))

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
* [BREAKING CHANGE] Change to store files on after_save hook instead of after_commit, with performing cleanup when transaction is rolled back (@fsateler [#2546](https://github.com/carrierwaveuploader/carrierwave/pull/2546))

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

Please check [2.x-stable](https://github.com/carrierwaveuploader/carrierwave/blob/2.x-stable/CHANGELOG.md) for previous changes.
