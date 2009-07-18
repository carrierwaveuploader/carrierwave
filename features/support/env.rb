# encoding: utf-8

$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require File.join(File.dirname(__FILE__), 'activerecord')
require File.join(File.dirname(__FILE__), 'datamapper')

if ENV["AS"]
  puts "--> using ActiveSupport"
  require 'activesupport'
elsif ENV["EXTLIB"]
  puts "--> using Extlib"
  require 'extlib'
end

require 'tempfile'
#require 'ruby-debug'
require 'spec'

require 'carrierwave'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), '..', *paths))
end

CarrierWave.config[:public] = file_path('public')
CarrierWave.config[:root] = file_path

After do
  FileUtils.rm_rf(file_path("public"))
end
