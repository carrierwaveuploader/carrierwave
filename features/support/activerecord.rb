# encoding: utf-8

unless defined?(JRUBY_VERSION)
  # not sure why we need to do this
  require 'sqlite3/sqlite3_native'
  require 'sqlite3'
end

require 'active_record'
require 'carrierwave/mount'
require 'carrierwave/orm/activerecord'

# change this if sqlite is unavailable
dbconfig = {
  :adapter => 'sqlite3',
  :database => ':memory:'
}

ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.column :avatar, :string
    end
  end

  def self.down
    drop_table :users
  end
end

Before do
  TestMigration.up
end
