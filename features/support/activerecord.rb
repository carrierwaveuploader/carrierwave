# encoding: utf-8

require 'mysql2'

require 'active_record'
require 'carrierwave/mount'
require 'carrierwave/orm/activerecord'

# Change this if MySQL is unavailable
dbconfig = {
  :adapter  => 'mysql2',
  :database => 'carrierwave_test',
  :username => 'root',
  :encoding => 'utf8'
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
