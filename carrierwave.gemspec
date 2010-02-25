# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{carrierwave}
  s.version = "0.4.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonas Nicklas"]
  s.date = %q{2010-02-18}
  s.description = %q{* RDoc Documentation {available at Rubyforge}[http://carrierwave.rubyforge.org/rdoc].
* Source code {hosted at GitHub}[http://github.com/jnicklas/carrierwave]
* Please {report any issues}[http://github.com/jnicklas/carrierwave/issues] on GitHub
* Please direct any questions at the {mailing list}[http://groups.google.com/group/carrierwave]
* Check out the {example app}[http://github.com/jnicklas/carrierwave-example-app]}
  s.email = ["jonas.nicklas@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "features/fixtures/bork.txt", "features/fixtures/monkey.txt", "README.rdoc"]
  s.files = ["Generators", "History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "cucumber.yml", "features/caching.feature", "features/download.feature", "features/file_storage.feature", "features/file_storage_overridden_filename.feature", "features/file_storage_overridden_store_dir.feature", "features/file_storage_reversing_processor.feature", "features/fixtures/bork.txt", "features/fixtures/monkey.txt", "features/grid_fs_storage.feature", "features/mount_activerecord.feature", "features/mount_datamapper.feature", "features/step_definitions/activerecord_steps.rb", "features/step_definitions/caching_steps.rb", "features/step_definitions/datamapper_steps.rb", "features/step_definitions/download_steps.rb", "features/step_definitions/file_steps.rb", "features/step_definitions/general_steps.rb", "features/step_definitions/mount_steps.rb", "features/step_definitions/store_steps.rb", "features/support/activerecord.rb", "features/support/datamapper.rb", "features/support/env.rb", "features/versions_basics.feature", "features/versions_nested_versions.feature", "features/versions_overridden_filename.feature", "features/versions_overriden_store_dir.feature", "lib/carrierwave.rb", "lib/carrierwave/compatibility/paperclip.rb", "lib/carrierwave/core_ext/blank.rb", "lib/carrierwave/core_ext/inheritable_attributes.rb", "lib/carrierwave/core_ext/module_setup.rb", "lib/carrierwave/mount.rb", "lib/carrierwave/orm/activerecord.rb", "lib/carrierwave/orm/datamapper.rb", "lib/carrierwave/orm/mongoid.rb", "lib/carrierwave/orm/mongomapper.rb", "lib/carrierwave/orm/sequel.rb", "lib/carrierwave/processing/image_science.rb", "lib/carrierwave/processing/mini_magick.rb", "lib/carrierwave/processing/rmagick.rb", "lib/carrierwave/sanitized_file.rb", "lib/carrierwave/storage/abstract.rb", "lib/carrierwave/storage/cloud_files.rb", "lib/carrierwave/storage/file.rb", "lib/carrierwave/storage/grid_fs.rb", "lib/carrierwave/storage/right_s3.rb", "lib/carrierwave/storage/s3.rb", "lib/carrierwave/test/matchers.rb", "lib/carrierwave/uploader.rb", "lib/carrierwave/uploader/cache.rb", "lib/carrierwave/uploader/callbacks.rb", "lib/carrierwave/uploader/configuration.rb", "lib/carrierwave/uploader/default_url.rb", "lib/carrierwave/uploader/download.rb", "lib/carrierwave/uploader/extension_whitelist.rb", "lib/carrierwave/uploader/mountable.rb", "lib/carrierwave/uploader/processing.rb", "lib/carrierwave/uploader/proxy.rb", "lib/carrierwave/uploader/remove.rb", "lib/carrierwave/uploader/store.rb", "lib/carrierwave/uploader/url.rb", "lib/carrierwave/uploader/versions.rb", "merb_generators/uploader_generator.rb", "rails_generators/uploader/USAGE", "rails_generators/uploader/templates/uploader.rb", "rails_generators/uploader/uploader_generator.rb", "script/console", "script/destroy", "script/generate", "spec/compatibility/paperclip_spec.rb", "spec/fixtures/bork.txt", "spec/fixtures/landscape.jpg", "spec/fixtures/portrait.jpg", "spec/fixtures/test.jpeg", "spec/fixtures/test.jpg", "spec/mount_spec.rb", "spec/orm/activerecord_spec.rb", "spec/orm/datamapper_spec.rb", "spec/orm/mongoid_spec.rb", "spec/orm/mongomapper_spec.rb", "spec/orm/sequel_spec.rb", "spec/processing/image_science_spec.rb", "spec/processing/mini_magick_spec.rb", "spec/processing/rmagick_spec.rb", "spec/sanitized_file_spec.rb", "spec/spec_helper.rb", "spec/storage/grid_fs_spec.rb", "spec/storage/right_s3_spec.rb", "spec/storage/s3_spec.rb", "spec/uploader/cache_spec.rb", "spec/uploader/configuration_spec.rb", "spec/uploader/default_url_spec.rb", "spec/uploader/download_spec.rb", "spec/uploader/extension_whitelist_spec.rb", "spec/uploader/mountable_spec.rb", "spec/uploader/paths_spec.rb", "spec/uploader/processing_spec.rb", "spec/uploader/proxy_spec.rb", "spec/uploader/remove_spec.rb", "spec/uploader/store_spec.rb", "spec/uploader/url_spec.rb", "spec/uploader/versions_spec.rb"]
  s.homepage = %q{http://carrierwave.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrierwave}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{* RDoc Documentation {available at Rubyforge}[http://carrierwave.rubyforge.org/rdoc]}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.5.2"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.8"])
      s.add_development_dependency(%q<cucumber>, [">= 0.3.96"])
      s.add_development_dependency(%q<activerecord>, [">= 2.3.3"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
      s.add_development_dependency(%q<dm-core>, [">= 0.9.11"])
      s.add_development_dependency(%q<data_objects>, [">= 0.9.12"])
      s.add_development_dependency(%q<do_sqlite3>, [">= 0.9.11"])
      s.add_development_dependency(%q<sequel>, [">= 3.2.0"])
      s.add_development_dependency(%q<rmagick>, [">= 2.10.0"])
      s.add_development_dependency(%q<mini_magick>, [">= 1.2.5"])
      s.add_development_dependency(%q<mongo_mapper>, [">= 0.6.8"])
      s.add_development_dependency(%q<mongoid>, [">= 0.10.4"])
      s.add_development_dependency(%q<aws-s3>, [">= 0.6.2"])
      s.add_development_dependency(%q<timecop>, [">= 0.3.4"])
      s.add_development_dependency(%q<json>, [">= 1.1.9"])
      s.add_development_dependency(%q<hoe>, [">= 2.4.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.5.2"])
      s.add_dependency(%q<rspec>, [">= 1.2.8"])
      s.add_dependency(%q<cucumber>, [">= 0.3.96"])
      s.add_dependency(%q<activerecord>, [">= 2.3.3"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
      s.add_dependency(%q<dm-core>, [">= 0.9.11"])
      s.add_dependency(%q<data_objects>, [">= 0.9.12"])
      s.add_dependency(%q<do_sqlite3>, [">= 0.9.11"])
      s.add_dependency(%q<sequel>, [">= 3.2.0"])
      s.add_dependency(%q<rmagick>, [">= 2.10.0"])
      s.add_dependency(%q<mini_magick>, [">= 1.2.5"])
      s.add_dependency(%q<mongo_mapper>, [">= 0.6.8"])
      s.add_dependency(%q<mongoid>, [">= 0.10.4"])
      s.add_dependency(%q<aws-s3>, [">= 0.6.2"])
      s.add_dependency(%q<timecop>, [">= 0.3.4"])
      s.add_dependency(%q<json>, [">= 1.1.9"])
      s.add_dependency(%q<hoe>, [">= 2.4.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.5.2"])
    s.add_dependency(%q<rspec>, [">= 1.2.8"])
    s.add_dependency(%q<cucumber>, [">= 0.3.96"])
    s.add_dependency(%q<activerecord>, [">= 2.3.3"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
    s.add_dependency(%q<dm-core>, [">= 0.9.11"])
    s.add_dependency(%q<data_objects>, [">= 0.9.12"])
    s.add_dependency(%q<do_sqlite3>, [">= 0.9.11"])
    s.add_dependency(%q<sequel>, [">= 3.2.0"])
    s.add_dependency(%q<rmagick>, [">= 2.10.0"])
    s.add_dependency(%q<mini_magick>, [">= 1.2.5"])
    s.add_dependency(%q<mongo_mapper>, [">= 0.6.8"])
    s.add_dependency(%q<mongoid>, [">= 0.10.4"])
    s.add_dependency(%q<aws-s3>, [">= 0.6.2"])
    s.add_dependency(%q<timecop>, [">= 0.3.4"])
    s.add_dependency(%q<json>, [">= 1.1.9"])
    s.add_dependency(%q<hoe>, [">= 2.4.0"])
  end
end
