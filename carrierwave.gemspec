# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'carrierwave/version'
require 'date'

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

  s.add_dependency "activesupport", ">= 3.2.0"
  s.add_dependency "activemodel", ">= 3.2.0"
  s.add_dependency "multi_json", "~> 1"

  s.add_development_dependency "mysql2"
  s.add_development_dependency "rails", ">= 3.2.0"
  s.add_development_dependency "cucumber", "~> 1.1.4"
  s.add_development_dependency "json"
  s.add_development_dependency "rspec", "~> 2.13.0"
  s.add_development_dependency "sham_rack"
  s.add_development_dependency "timecop"
  s.add_development_dependency "fog", ">= 1.3.1"
  s.add_development_dependency "mini_magick"
  s.add_development_dependency "rmagick"
end
