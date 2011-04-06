# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'carrierwave/version'

Gem::Specification.new do |s|
  s.name = "carrierwave"
  s.version = CarrierWave::VERSION

  s.authors = ["Jonas Nicklas"]
  s.date = Date.today
  s.description = "Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends."
  s.summary = "Ruby file upload library"
  s.email = ["jonas.nicklas@gmail.com"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = Dir.glob("{bin,lib}/**/*") + %w(README.rdoc)
  s.homepage = %q{https://github.com/jnicklas/carrierwave}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrierwave}
  s.rubygems_version = %q{1.3.5}
  s.specification_version = 3

  s.add_dependency("activesupport", ["~> 3.0"])

  s.add_development_dependency "rails", ["3.0.5"]
  s.add_development_dependency "rspec", ["1.3.0"]
  s.add_development_dependency "excon", ["0.6.1"]
  s.add_development_dependency "fog", ["0.7.2"]
  s.add_development_dependency "cucumber", ["0.8.5"]
  s.add_development_dependency "sqlite3", ["1.3.3"]
  s.add_development_dependency "dm-core", ["1.0.0"]
  s.add_development_dependency "dm-validations", ["1.0.0"]
  s.add_development_dependency "dm-migrations", ["1.0.0"]
  s.add_development_dependency "dm-sqlite-adapter", ["1.0.0"]
  s.add_development_dependency "sequel", ["3.14.0"]
  s.add_development_dependency "rmagick", ["2.13.1"]
  s.add_development_dependency "RubyInline", ["3.8.4"]
  s.add_development_dependency "image_science", ["1.2.1"]
  s.add_development_dependency "mini_magick", ["2.3"]
  s.add_development_dependency "bson_ext", ["1.2.4"]
  s.add_development_dependency "mongoid", ["2.0.0.beta.19"]
  s.add_development_dependency "timecop", ["0.3.5"]
  s.add_development_dependency "json", ["1.5.1"]
  s.add_development_dependency "cloudfiles", ["1.4.12"]
  s.add_development_dependency "sham_rack", ["1.3.3"]
end
