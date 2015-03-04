if RUBY_ENGINE == 'jruby'
  require 'activerecord-jdbcpostgresql-adapter'
else
  require 'pg'
end
require 'active_record'
require 'carrierwave/orm/activerecord'

# Change this if PG is unavailable
dbconfig = {
  :adapter  => 'postgresql',
  :database => 'carrierwave_test',
  :encoding => 'utf8',
  :username => 'postgres'
}

database = dbconfig.delete(:database)

ActiveRecord::Base.establish_connection(dbconfig.merge(database: "template1"))
begin
  ActiveRecord::Base.connection.create_database database
rescue ActiveRecord::StatementInvalid => e # database already exists
end
ActiveRecord::Base.establish_connection(dbconfig.merge(:database => database))

ActiveRecord::Migration.verbose = false
