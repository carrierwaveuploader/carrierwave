# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'carrierwave/version'

Gem::Specification.new do |s|
  s.name = "carrierwave"
  s.version = CarrierWave::VERSION

  s.authors = ["Jonas Nicklas"]
  s.description = "Upload files in your Ruby applications, map them to a range of ORMs, store them on different backends."
  s.summary = "Ruby file upload library"
  s.email = ["jonas.nicklas@gmail.com"]
  s.extra_rdoc_files = ["README.md"]
  s.files = Dir["{bin,lib}/**/*", "README.md"]
  s.homepage = %q{https://github.com/carrierwaveuploader/carrierwave}
  s.rdoc_options = ["--main"]
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]

  s.required_ruby_version = ">= 2.1.0"

  s.add_dependency "activesupport", ">= 4.0.0"
  s.add_dependency "activemodel", ">= 4.0.0"
  s.add_dependency "mime-types", ">= 1.16"
  if RUBY_ENGINE == 'jruby'
    s.add_development_dependency 'activerecord-jdbcpostgresql-adapter'
  else
    s.add_development_dependency "pg"
  end
  s.add_development_dependency "rails", ">= 4.0.0"
  s.add_development_dependency "cucumber", "~> 2.3"
  s.add_development_dependency "rspec", "~> 3.4"
  s.add_development_dependency "webmock"
  s.add_development_dependency "fog-aws"
  s.add_development_dependency "fog-google", "<= 0.1.0"
  s.add_development_dependency "fog-local"
  s.add_development_dependency "fog-rackspace"
  s.add_development_dependency "mini_magick", ">= 3.6.0"
  if RUBY_ENGINE != 'jruby'
    s.add_development_dependency "rmagick"
  end
  s.add_development_dependency "timecop"
  s.add_development_dependency "generator_spec", ">= 0.9.1"
  s.add_development_dependency "pry"
end
