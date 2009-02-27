# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{carrier_wave}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonas Nicklas"]
  s.date = %q{2009-02-27}
  s.description = %q{Simple and powerful uploads for Merb and Rails}
  s.email = %q{jonas.nicklas@gmail.com}
  s.extra_rdoc_files = ["README.md", "LICENSE", "TODO"]
  s.files = ["LICENSE", "Generators", "README.md", "Rakefile", "TODO", "lib/carrier_wave", "lib/carrier_wave/mount.rb", "lib/carrier_wave/orm", "lib/carrier_wave/orm/activerecord.rb", "lib/carrier_wave/orm/datamapper.rb", "lib/carrier_wave/processing", "lib/carrier_wave/processing/image_science.rb", "lib/carrier_wave/processing/rmagick.rb", "lib/carrier_wave/sanitized_file.rb", "lib/carrier_wave/storage", "lib/carrier_wave/storage/abstract.rb", "lib/carrier_wave/storage/file.rb", "lib/carrier_wave/storage/s3.rb", "lib/carrier_wave/uploader.rb", "lib/carrier_wave.rb", "lib/generators", "lib/generators/templates", "lib/generators/templates/uploader.rbt", "lib/generators/uploader_generator.rb", "spec/fixtures", "spec/fixtures/bork.txt", "spec/fixtures/test.jpeg", "spec/fixtures/test.jpg", "spec/mount_spec.rb", "spec/orm", "spec/orm/activerecord_spec.rb", "spec/orm/datamapper_spec.rb", "spec/public", "spec/public/uploads", "spec/public/uploads/jonas.jpeg", "spec/public/uploads/test.jpeg", "spec/public/uploads/tmp", "spec/public/uploads/tmp/20090227-2320-61453-0083", "spec/public/uploads/tmp/20090227-2320-61453-1505", "spec/public/uploads/tmp/20090227-2320-61453-4558", "spec/public/uploads/tmp/20090227-2320-61453-4558/test.jpeg", "spec/public/uploads/tmp/20090227-2320-61453-4696", "spec/public/uploads/tmp/20090227-2320-61453-5125", "spec/public/uploads/tmp/20090227-2320-61453-6470", "spec/public/uploads/tmp/20090227-2320-61453-6470/test.jpeg", "spec/public/uploads/tmp/20090227-2320-61453-6646", "spec/public/uploads/tmp/20090227-2320-61453-6646/test.jpeg", "spec/public/uploads/tmp/20090227-2321-61462-3503", "spec/public/uploads/tmp/20090227-2321-61462-3503/test.jpeg", "spec/public/uploads/tmp/20090227-2321-61462-4613", "spec/public/uploads/tmp/20090227-2321-61462-4613/test.jpeg", "spec/public/uploads/tmp/20090227-2321-61462-4735", "spec/public/uploads/tmp/20090227-2321-61462-9117", "spec/sanitized_file_spec.rb", "spec/spec_helper.rb", "spec/uploader_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.example.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrier_wave}
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
