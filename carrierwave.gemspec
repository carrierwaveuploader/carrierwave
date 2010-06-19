# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "carrierwave"
  s.version = "0.4.4"

  s.authors = ["Jonas Nicklas"]
  s.date = Date.today
  s.description = "Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends."
  s.summary = "Ruby file upload library"
  s.email = ["jonas.nicklas@gmail.com"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = Dir.glob("{bin,lib}/**/*") + %w(README.rdoc)
  s.homepage = %q{http://carrierwave.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrierwave}
  s.rubygems_version = %q{1.3.5}
  s.specification_version = 3

  s.add_development_dependency("rspec", [">= 1.2.8"])
  s.add_development_dependency("cucumber", [">= 0.3.96"])
  s.add_development_dependency("activerecord", [">= 2.3.3"])
  s.add_development_dependency("sqlite3-ruby", [">= 1.2.5"])
  s.add_development_dependency("dm-core", [">= 1.0.0"])
  s.add_development_dependency("dm-validations", [">= 1.0.0"])
  s.add_development_dependency("dm-migrations", [">= 1.0.0"])
  s.add_development_dependency("dm-sqlite-adapter", [">= 1.0.0"])
  s.add_development_dependency("sequel", [">= 3.2.0"])
  s.add_development_dependency("rmagick", [">= 2.10.0"])
  s.add_development_dependency("RubyInline", [">= 2.10.0"])
  s.add_development_dependency("image_science", [">= 2.10.0"])
  s.add_development_dependency("mini_magick", [">= 1.2.5"])
  s.add_development_dependency("mongoid", [">= 0.10.4"])
  s.add_development_dependency("aws-s3", [">= 0.6.2"])
  s.add_development_dependency("timecop", [">= 0.3.4"])
  s.add_development_dependency("json", [">= 1.1.9"])
end
