$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'extlib'
require 'tempfile'
require 'ruby-debug'
require 'spec'

require 'merb_upload'

Merb::Upload.config[:public] = File.dirname(__FILE__) / 'public'
Merb::Upload.config[:store_dir] = File.dirname(__FILE__) / 'public' / 'uploads'
Merb::Upload.config[:cache_dir] = File.dirname(__FILE__) / 'public' / 'uploads' / 'tmp'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end

After do
  FileUtils.rm_rf(file_path("public"))
end
