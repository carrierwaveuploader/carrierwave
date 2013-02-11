# encoding: utf-8

require 'carrierwave/mount'
require File.join(File.dirname(__FILE__), '..', '..', 'spec', 'support', 'activerecord')

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
