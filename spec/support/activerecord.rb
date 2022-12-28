require 'active_record'
require 'carrierwave/orm/activerecord'
Bundler.require

ActiveRecord::Base.establish_connection({ adapter: 'sqlite3', database: ':memory:' })

ActiveRecord::Migration.verbose = false

if ActiveRecord.version < Gem::Version.new("5.2") && ActiveRecord.version >= Gem::Version.new("5.0")
  module ActiveRecord
    module Type
      class Json < ActiveModel::Type::Value
        include ActiveModel::Type::Helpers::Mutable

        def type
          :json
        end

        def deserialize(value)
          return value unless value.is_a?(::String)
          ActiveSupport::JSON.decode(value) rescue nil
        end

        def serialize(value)
          ActiveSupport::JSON.encode(value) unless value.nil?
        end

        def changed_in_place?(raw_old_value, new_value)
          deserialize(raw_old_value) != new_value
        end

        def accessor
          ActiveRecord::Store::StringKeyedHashAccessor
        end
      end
    end
  end

  ActiveRecord::Type.register(:json, ActiveRecord::Type::Json, override: false)
end

if ActiveRecord::VERSION::STRING >= '4.2' && ActiveRecord::VERSION::STRING < '5.0'
    ActiveRecord::Base.raise_in_transactional_callbacks = true
end
