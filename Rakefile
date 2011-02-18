# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
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
