# encoding: utf-8

$TESTING=true
$:.unshift File.expand_path(File.join('..', '..', 'lib'), File.dirname(__FILE__))

require File.join(File.dirname(__FILE__), 'activerecord')
require File.join(File.dirname(__FILE__), 'datamapper')

require 'spec'
require 'carrierwave'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join('..', *paths), File.dirname(__FILE__))
end

CarrierWave.root = file_path('public')

After do
  FileUtils.rm_rf(file_path("public"))
end
