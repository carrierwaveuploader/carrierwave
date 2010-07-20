# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "carrierwave"
  s.version = "0.5.0.beta1"

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

  s.add_dependency("activesupport", [">= 3.0.0.beta4"])
end
