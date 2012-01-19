# encoding: utf-8

$:.unshift File.expand_path(File.join('..', '..', 'lib'), File.dirname(__FILE__))

require File.join(File.dirname(__FILE__), 'activerecord')

require 'rspec'
require 'carrierwave'
require 'sham_rack'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join('..', *paths), File.dirname(__FILE__))
end

CarrierWave.root = file_path('public')

After do
  FileUtils.rm_rf(file_path("public"))
end
