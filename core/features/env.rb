$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'merb-core'
require 'tempfile'
require 'ruby-debug'
require 'spec'

Merb.root = File.dirname(__FILE__)

require 'merb_upload'

alias :running :lambda

Merb.push_path(:public, File.dirname(__FILE__) / "public", nil)

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end

After do
  FileUtils.rm_rf(file_path("public"))
end
