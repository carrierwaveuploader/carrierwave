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

  s.add_development_dependency "rails", ["~> 3.0"]
  s.add_development_dependency "rspec", ["~> 1.3"]
  s.add_development_dependency "fog", ["~> 0.5"]
  s.add_development_dependency "cucumber"
  s.add_development_dependency "sqlite3-ruby"
  s.add_development_dependency "dm-core"
  s.add_development_dependency "dm-validations"
  s.add_development_dependency "dm-migrations"
  s.add_development_dependency "dm-sqlite-adapter"
  s.add_development_dependency "sequel"
  s.add_development_dependency "rmagick"
  s.add_development_dependency "RubyInline"
  s.add_development_dependency "image_science"
  s.add_development_dependency "mini_magick", ["~> 2.3"]
  s.add_development_dependency "bson_ext", ["= 1.1.1"]
  s.add_development_dependency "mongoid", ["= 2.0.0.beta.19"]
  s.add_development_dependency "timecop"
  s.add_development_dependency "json"
  s.add_development_dependency "cloudfiles", [">= 1.4.12"]
end
