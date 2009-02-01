$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'merb-core'
require 'tempfile'
require 'ruby-debug'
require 'spec'

require File.join(File.dirname(__FILE__), *%w[.. .. .. core lib merb_upload])

require 'merb_upload_datamapper'

DataMapper.setup(:default, 'sqlite3::memory:')

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

def public_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public', *paths))
end

def stub_file(filename, mime_type=nil, fake_name=nil)
  f = File.open(file_path(filename))
  return f
end