# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{carrierwave}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonas Nicklas"]
  s.date = %q{2009-05-01}
  s.description = %q{Simple and powerful uploads for Merb and Rails}
  s.email = %q{jonas.nicklas@gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "TODO"]
  s.files = ["LICENSE", "Generators", "README.rdoc", "Rakefile", "TODO", "lib/carrierwave", "lib/carrierwave/mount.rb", "lib/carrierwave/orm", "lib/carrierwave/orm/activerecord.rb", "lib/carrierwave/orm/datamapper.rb", "lib/carrierwave/orm/sequel.rb", "lib/carrierwave/processing", "lib/carrierwave/processing/image_science.rb", "lib/carrierwave/processing/rmagick.rb", "lib/carrierwave/sanitized_file.rb", "lib/carrierwave/storage", "lib/carrierwave/storage/abstract.rb", "lib/carrierwave/storage/file.rb", "lib/carrierwave/storage/s3.rb", "lib/carrierwave/test", "lib/carrierwave/test/matchers.rb", "lib/carrierwave/uploader.rb", "lib/carrierwave.rb", "lib/generators", "lib/generators/uploader_generator.rb", "spec/fixtures", "spec/fixtures/bork.txt", "spec/fixtures/test.jpeg", "spec/fixtures/test.jpg", "spec/mount_spec.rb", "spec/orm", "spec/orm/activerecord_spec.rb", "spec/orm/datamapper_spec.rb", "spec/orm/sequel_spec.rb", "spec/sanitized_file_spec.rb", "spec/spec_helper.rb", "spec/uploader_spec.rb", "rails_generators/uploader", "rails_generators/uploader/templates", "rails_generators/uploader/templates/uploader.rb", "rails_generators/uploader/uploader_generator.rb", "rails_generators/uploader/USAGE"]
  s.has_rdoc = true
  s.homepage = %q{http://www.example.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrierwave}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Simple and powerful uploads for Merb and Rails}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
