$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'merb-core'
require 'tempfile'
require 'ruby-debug'
require 'spec'

require 'merb_upload'

Merb.push_path(:public, File.dirname(__FILE__) / 'public', nil)
Merb.root = File.dirname(__FILE__)

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), *paths))
end

After do
  FileUtils.rm_rf(File.dirname(__FILE__) / 'public')
end
