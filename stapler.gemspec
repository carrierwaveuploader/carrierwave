# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{stapler}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonas Nicklas"]
  s.date = %q{2009-02-26}
  s.description = %q{Simple and powerful uploads for Merb and Rails}
  s.email = %q{jonas.nicklas@gmail.com}
  s.extra_rdoc_files = ["README.md", "LICENSE", "TODO"]
  s.files = ["LICENSE", "Generators", "README.md", "Rakefile", "TODO", "lib/generators", "lib/generators/templates", "lib/generators/templates/uploader.rbt", "lib/generators/uploader_generator.rb", "lib/stapler", "lib/stapler/mount.rb", "lib/stapler/orm", "lib/stapler/orm/activerecord.rb", "lib/stapler/orm/datamapper.rb", "lib/stapler/processing", "lib/stapler/processing/image_science.rb", "lib/stapler/processing/rmagick.rb", "lib/stapler/sanitized_file.rb", "lib/stapler/storage", "lib/stapler/storage/abstract.rb", "lib/stapler/storage/file.rb", "lib/stapler/storage/s3.rb", "lib/stapler/uploader.rb", "lib/stapler.rb", "spec/fixtures", "spec/fixtures/bork.txt", "spec/fixtures/test.jpeg", "spec/fixtures/test.jpg", "spec/mount_spec.rb", "spec/orm", "spec/orm/activerecord_spec.rb", "spec/orm/datamapper_spec.rb", "spec/sanitized_file_spec.rb", "spec/spec_helper.rb", "spec/uploader_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.example.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{stapler}
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
