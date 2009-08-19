require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/carrierwave'

Hoe.plugin :newgem
# Hoe.plugin :website
Hoe.plugin :cucumberfeatures

$hoe = Hoe.spec 'carrierwave' do
  self.developer 'Jonas Nicklas', 'jonas.nicklas@gmail.com'
  self.rubyforge_name = self.name
  self.readme_file = 'README.rdoc'
  self.version = CarrierWave::VERSION
  self.extra_dev_deps << ['rspec', '>=1.2.8']
  self.extra_dev_deps << ['cucumber', '>=0.3.96']
  self.extra_dev_deps << ['activerecord', '>=2.3.3']
  self.extra_dev_deps << ['dm-core', '>=0.9.11']
  self.extra_dev_deps << ['sequel', '>=3.2.0']
  self.extra_dev_deps << ['rmagick', '>=2.10.0']
  self.extra_rdoc_files << 'README.rdoc'
  self.extra_rdoc_files << 'LICENSE'
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

task :default => [:spec, :features]
