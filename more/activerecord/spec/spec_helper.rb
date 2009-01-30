$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'merb-core'
require 'tempfile'
require 'ruby-debug'
require 'spec'

require 'activerecord'

require File.join(File.dirname(__FILE__), *%w[.. .. .. core lib merb_upload])

require 'merb_upload_activerecord'

# change this if sqlite is unavailable
dbconfig = {
  :adapter => 'sqlite3',
  :database => 'db/test.sqlite3'
}

ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :events, :force => true do |t|
      t.column :image, :string
      t.column :textfile, :string
    end
  end

  def self.down
    drop_table :events
  end
end

class Event < ActiveRecord::Base; end # setup a basic AR class for testing

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