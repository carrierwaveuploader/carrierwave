require 'pg'
require 'rails'
require 'carrierwave/orm/activerecord'

# Change this if PG is unavailable
dbconfig = {
  :adapter  => 'postgresql',
  :database => 'carrierwave_test',
  :encoding => 'utf8',
  :username => 'postgres'
}

ActiveRecord::Base.establish_connection(dbconfig)

ActiveRecord::Migration.verbose = false
