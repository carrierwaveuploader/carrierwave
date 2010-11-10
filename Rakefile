require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'

desc "Run all examples"
RSpec::Core::RakeTask.new do |t|
  # t.spec_files = FileList['spec/**/*.rb']
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Run cucumber features"
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress"
end

task :default => [:spec, :features]
