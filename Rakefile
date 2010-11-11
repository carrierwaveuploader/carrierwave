require 'rubygems'
require 'bundler/setup'
require 'spec/rake/spectask'
require 'cucumber'
require 'cucumber/rake/task'

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

desc "Run cucumber features"
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress"
end


task :default => [:spec, :features]
