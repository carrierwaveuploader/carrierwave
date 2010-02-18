require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'carrierwave'

Hoe.plugin :newgem
# Hoe.plugin :website
Hoe.plugin :cucumberfeatures

$hoe = Hoe.spec 'carrierwave' do
  self.developer 'Jonas Nicklas', 'jonas.nicklas@gmail.com'
  self.rubyforge_name = self.name
  self.readme_file = 'README.rdoc'
  self.version = CarrierWave::VERSION
  self.extra_dev_deps << ['newgem', '>=1.5.2']
  self.extra_dev_deps << ['rspec', '>=1.2.8']
  self.extra_dev_deps << ['cucumber', '>=0.3.96']
  self.extra_dev_deps << ['activerecord', '>=2.3.3']
  self.extra_dev_deps << ['sqlite3-ruby', '>=1.2.5']
  self.extra_dev_deps << ['dm-core', '>=0.9.11']
  self.extra_dev_deps << ['data_objects', '>=0.9.12']
  self.extra_dev_deps << ['do_sqlite3', '>=0.9.11']
  self.extra_dev_deps << ['sequel', '>=3.2.0']
  self.extra_dev_deps << ['rmagick', '>=2.10.0']
  self.extra_dev_deps << ['mini_magick', '>=1.2.5']
  self.extra_dev_deps << ['mongo_mapper', '>=0.6.8']
  self.extra_dev_deps << ['mongoid', '>=0.10.4']
  self.extra_dev_deps << ['aws-s3', '>=0.6.2']
  self.extra_dev_deps << ['timecop', '>=0.3.4']
  self.extra_dev_deps << ['json', '>=1.1.9']
  self.extra_rdoc_files << 'README.rdoc'
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

task :default => [:spec, :features]
