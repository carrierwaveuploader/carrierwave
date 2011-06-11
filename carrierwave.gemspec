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
  s.extra_rdoc_files = ["README.md"]
  s.files = Dir.glob("{bin,lib}/**/*") + %w(README.md)
  s.homepage = %q{https://github.com/jnicklas/carrierwave}
  s.rdoc_options = ["--main"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{carrierwave}
  s.rubygems_version = %q{1.3.5}
  s.specification_version = 3

  s.add_dependency("activesupport", ["~> 3.0"])

  s.add_development_dependency "rails", ["~> 3.0"]
  s.add_development_dependency "rspec", ["~> 2.0"]
  s.add_development_dependency "excon"
  s.add_development_dependency "fog"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rmagick"
  s.add_development_dependency "RubyInline"
  s.add_development_dependency "image_science"
  s.add_development_dependency "mini_magick"
  s.add_development_dependency "bson_ext"
  s.add_development_dependency "mongoid"
  s.add_development_dependency "timecop"
  s.add_development_dependency "json"
  s.add_development_dependency "cloudfiles"
  s.add_development_dependency "sham_rack"
end
