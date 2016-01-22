# Carrierwave History/Changelog

## Unreleased

* [added] Add a test matcher for the format (@yanivpr)
* 2015-11-26 5217412  Merge pull request #1721 from Deradon/feature/file-storage_cache-with-clean-on-exception [Thomas Drake-Brockman]
* 2015-08-16 d74ee6b  Store::File#cache! will retry after Errno::EMLINK [Patrick Helm]
* [changed] Better error when the configured storage is unknown (@st0012)
* [BREAKING CHANGE] Allow non-ASCII filename by default (@shuhei)
* [added] Add Indonesian i18n translations for errors (@saveav)
* [added] Support of MiniMagick's Combine options (@bernabas)
* [fixed] Fix `Mounter.blank?` method (@Bonias)
* [fixed] Reset `remove_#{column}` after invoking `remove_#{column}` (@eavgerinos)
* 2015-08-18 80d53e5  Merge pull request #1672 from kuraga/fix-1495 [James Miller]
* [changed] Allow to pass additionnal options to Rackspace `authenticated_url` (@duhast)
* [changed] Reduced memory footprint (@schneems, @simonprev)
* [fixed] Change Google's url to the public_url (@m7moud)
* 2015-06-09 6a5e133  Shouldn't affect parent class' version (closes #1495) [Kurakin Alexander]
* [added] Add Taiwanese i18n translations for errors (@st0012)
* [fixed] Do not write to ActiveModel::Dirty changes when assigning something blank to a mounter that was originally blank (@eavgerinos)
* [changed] Improve Fog Loading (@plribeiro3000, @eavgerinos)
* [added] Validate with the actual content-type of files (@eavgerinos)
* [fixed] Various grammar and typos fixes to error messages translations
* [fixed] Don't error when size is called on a deleted file (@danielevans)
* [fixed] Flush mounters on dup of active record model(@danielevans)
* [changed] All locales from `config.i18n.available_locales` are added to load_path (@printercu)
* [fixed] Fog::File.read returns its contents after upload instead of "closed stream" error (@stormsilver)
* 2014-11-19 0ceac65  Merge pull request #1503 from huacnlee/fix_remove_previously_stored_in_transactions [James Miller]
* 2014-11-20 aadbe94  Fix bug with remove_previously_stored_#{column} callback, when updating in a transaction, and that process is rollback. Again~ [Jason Lee]
* [added] Add Chinese i18n translations for errors [msyesyan]
* 2014-11-19 f88ebde  Switch back to after_safe for removing previous columns, mark specs as pending [James Miller]
* 2014-11-18 79886e6  Merge pull request #1447 from huacnlee/fix_remove_previously_stored_in_transaction [James Miller]
* [added] Support setting a SanitizedFile where the content_type is found on the `:type` key of the file hash (@bensie)
* [BREAKING CHANGE] `to_json` behavior changed when serializing an uploader (@jnicklas and @lisarutan)
* [added] Support for multiple file uploads with `mount_uploaders` method (@jnicklas and @lisarutan)
* [fixed] Don't read file twice when calling `sanitized_file` or `cache!` (@felixbuenemann)
* [added] Add a `cache_only` configuration option, useful for testing (@jeffkreeftmeijer)
* 2014-08-27 bb02c9e  Fix bug with remove_previously_stored_#{column} callback, when updating in a transaction, and that process is rollback. The old file will be delete, but the new file name can not store success into database. [Jason Lee]
* [fixed] Change image extension when converting formats (@nashby)
* [fixed] Fix file delete being called twice on remove (@adamcrown)
* [fixed] RSpec 3 support
* [fixed] MiniMagick convert to a format all the pages by default and accept an optional page number parameter to convert specific pages (@harikrishnan83)
* [added] Add `#width` and `#height` methods to MiniMagick processor (@ShivaVS)
* [fixed] Fix cache workfile collision between versions (@jvdp)
* [fixed] Reset mounter cache on record reload (@semenyukdmitriy)
* [fixed] Retrieve only active versions of files (@filipegiusti)
* [added] Support for jRuby (@lephyrius)
* [changed] Do not display rmagick exception in I18n message (manuelpradal)
* [fixed] Fix default gravity in MiniMagick resize_and_pad (@abevoelker)
* [changed] `#default_url` now accepts the same args passed to `#url` (@shekibobo)
* [fixed] Skip loading RMagick if already loaded (@mshibuya)
* [fixed] Make the #remove_ accessor set the mounted column as changed (@nikz)
* [added] Make cache storage configurable (@mshibuya)
* [added] Errors on file size (@gautampunhani)

Please check [0.10-stable] for previous changes.

[0.10-stable]: https://github.com/carrierwaveuploader/carrierwave/blob/0.10-stable/History.txt
