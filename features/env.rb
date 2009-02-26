$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'

if ENV["AS"]
  puts "--> using ActiveSupport"
  require 'activesupport'
else
  puts "--> using Extlib"
  require 'extlib'
end

require 'tempfile'
require 'ruby-debug'
require 'spec'

require 'stapler'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end

Stapler.config[:public] = file_path('public')
Stapler.config[:root] = file_path
Stapler.config[:store_dir] = 'public/uploads'
Stapler.config[:cache_dir] = 'public/uploads/tmp'

After do
  FileUtils.rm_rf(file_path("public"))
end
