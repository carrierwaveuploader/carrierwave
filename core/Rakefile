require 'rubygems'
require 'rake/gempackagetask'

require 'yard'
require 'merb-core'
require 'merb-core/tasks/merb'
require 'spec/rake/spectask'
require 'cucumber/rake/task'

NAME = "merb_upload"
GEM_VERSION = "0.0.1"
AUTHOR = "Jonas Nicklas"
EMAIL = "jonas.nicklas@gmail.com"
HOMEPAGE = "http://merbivore.com/"
SUMMARY = "Merb plugin that provides a framework for file uploads"

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'merb'
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.require_path = 'lib'
  s.files = %w(LICENSE Generators README.md Rakefile TODO) + Dir.glob("{lib,spec}/**/*")
  
end

# Try these:
#
# rake features
# rake features PROFILE=html
Cucumber::Rake::Task.new do |t|
  profile = ENV['PROFILE'] || 'default'
  t.cucumber_opts = "--profile #{profile}"
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ["README.md", "LICENSE", "TODO", 'lib/merb_upload/**/*.rb']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the plugin locally"
task :install => [:package] do
  sh %{#{sudo} gem install #{install_home} pkg/#{NAME}-#{GEM_VERSION} --no-update-sources}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => :package do
    sh %{#{sudo} jruby -S gem install #{install_home} pkg/#{NAME}-#{GEM_VERSION}.gem --no-rdoc --no-ri}
  end

end

file_list = FileList['spec/**/*_spec.rb']

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = file_list
end

namespace :spec do
  desc "Run all examples with RCov"
  Spec::Rake::SpecTask.new('rcov') do |t|
    t.spec_files = file_list
    t.rcov = true
    t.rcov_dir = "doc/coverage"
    t.rcov_opts = ['--exclude', 'spec']
  end
  
  desc "Generate an html report"
  Spec::Rake::SpecTask.new('report') do |t|
    t.spec_files = file_list
    t.spec_opts = ["--format", "html:doc/reports/specs.html"]
    t.fail_on_error = false
  end

end

desc 'Default: run unit tests.'
task :default => 'spec'
