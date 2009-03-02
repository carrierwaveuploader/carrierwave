# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{carrierwave}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonas Nicklas"]
  s.date = %q{2009-03-02}
  s.description = %q{Simple and powerful uploads for Merb and Rails}
  s.email = %q{jonas.nicklas@gmail.com}
  s.extra_rdoc_files = ["README.md", "LICENSE", "TODO"]
  s.files = ["LICENSE", "Generators", "README.md", "Rakefile", "TODO", "lib/carrierwave", "lib/carrierwave/mount.rb", "lib/carrierwave/orm", "lib/carrierwave/orm/activerecord.rb", "lib/carrierwave/orm/datamapper.rb", "lib/carrierwave/processing", "lib/carrierwave/processing/image_science.rb", "lib/carrierwave/processing/rmagick.rb", "lib/carrierwave/sanitized_file.rb", "lib/carrierwave/storage", "lib/carrierwave/storage/abstract.rb", "lib/carrierwave/storage/file.rb", "lib/carrierwave/storage/s3.rb", "lib/carrierwave/uploader.rb", "lib/carrierwave.rb", "lib/generators", "lib/generators/templates", "lib/generators/templates/uploader.rbt", "lib/generators/uploader_generator.rb", "spec/fixtures", "spec/fixtures/bork.txt", "spec/fixtures/test.jpeg", "spec/fixtures/test.jpg", "spec/mount_spec.rb", "spec/orm", "spec/orm/activerecord_spec.rb", "spec/orm/datamapper_spec.rb", "spec/sanitized_file_spec.rb", "spec/spec_helper.rb", "spec/uploader_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.example.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrierwave}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Simple and powerful uploads for Merb and Rails}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
