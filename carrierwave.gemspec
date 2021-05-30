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

  s.required_ruby_version = ">= 2.5.0"

  s.add_dependency "activesupport", ">= 6.0.0"
  s.add_dependency "activemodel", ">= 6.0.0"
  s.add_dependency "image_processing", "~> 1.1"
  s.add_dependency "marcel", "~> 1.0.0"
  s.add_dependency "addressable", "~> 2.6"
  s.add_dependency "ssrf_filter", "~> 1.0"
  s.add_development_dependency "rails", ">= 6.0.0"
  s.add_development_dependency "cucumber", "~> 2.3"
  s.add_development_dependency "rspec", "~> 3.4"
  s.add_development_dependency "rspec-retry"
  s.add_development_dependency "webmock"
  s.add_development_dependency "fog-aws"
  s.add_development_dependency "fog-google", ["~> 1.7", "!= 1.12.1"]
  s.add_development_dependency "fog-local"
  s.add_development_dependency "fog-rackspace"
  s.add_development_dependency "mini_magick", ">= 3.6.0"
  if RUBY_ENGINE != 'jruby'
    s.add_development_dependency "rmagick", ">= 2.16"
  end
  s.add_development_dependency "timecop"
  s.add_development_dependency "generator_spec", ">= 0.9.1"
  s.add_development_dependency "pry"
  if RUBY_ENGINE != 'jruby'
    s.add_development_dependency "pry-byebug"
  end
end
