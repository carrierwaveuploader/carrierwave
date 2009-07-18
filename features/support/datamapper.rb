# encoding: utf-8

require 'dm-core'
require 'carrierwave/mount'
require 'carrierwave/orm/datamapper'

DataMapper.setup(:default, 'sqlite3::memory:')