# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_upload}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonas Nicklas"]
  s.date = %q{2009-02-16}
  s.description = %q{Merb plugin that provides a framework for file uploads}
  s.email = %q{jonas.nicklas@gmail.com}
  s.extra_rdoc_files = ["README.md", "LICENSE", "TODO"]
  s.files = ["LICENSE", "Generators", "README.md", "Rakefile", "TODO", "lib/generators", "lib/generators/templates", "lib/generators/templates/uploader.rbt", "lib/generators/uploader_generator.rb", "lib/merb_upload", "lib/merb_upload/mount.rb", "lib/merb_upload/orm", "lib/merb_upload/orm/activerecord.rb", "lib/merb_upload/orm/datamapper.rb", "lib/merb_upload/processing", "lib/merb_upload/processing/image_science.rb", "lib/merb_upload/processing/rmagick.rb", "lib/merb_upload/sanitized_file.rb", "lib/merb_upload/storage", "lib/merb_upload/storage/abstract.rb", "lib/merb_upload/storage/file.rb", "lib/merb_upload/storage/s3.rb", "lib/merb_upload/uploader.rb", "lib/merb_upload.rb", "spec/fixtures", "spec/fixtures/bork.txt", "spec/fixtures/test.jpeg", "spec/fixtures/test.jpg", "spec/mount_spec.rb", "spec/orm", "spec/orm/activerecord_spec.rb", "spec/orm/datamapper_spec.rb", "spec/sanitized_file_spec.rb", "spec/spec_helper.rb", "spec/uploader_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://merbivore.com/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Merb plugin that provides a framework for file uploads}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
