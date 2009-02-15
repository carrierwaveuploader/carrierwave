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

require 'merb_upload'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end

Merb::Upload.config[:public] = file_path('public')
Merb::Upload.config[:store_dir] = file_path('public', 'uploads')
Merb::Upload.config[:cache_dir] = file_path('public', 'uploads', 'tmp')

After do
  FileUtils.rm_rf(file_path("public"))
end
