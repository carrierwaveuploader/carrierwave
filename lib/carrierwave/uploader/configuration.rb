module CarrierWave
  
  module Uploader
    module Configuration
      
      setup do
        add_config :root
        add_config :permissions
        add_config :storage_engines
        add_config :s3_access
        add_config :s3_bucket
        add_config :s3_access_key_id
        add_config :s3_secret_access_key
        add_config :grid_fs_database
        add_config :grid_fs_host
        add_config :grid_fs_host
        add_config :store_dir
        add_config :cache_dir

        # Mounting
        add_config :ignore_integrity_errors
        add_config :ignore_processing_errors
        add_config :validate_integrity
        add_config :validate_processing
        add_config :mount_on
      end

      module ClassMethods

        def add_config(name, options={})
          extlib_inheritable_accessor name
          (class << self; self end).module_eval do
            alias_method :"#{name}_without_class_writer", name
            private :"#{name}_without_class_writer"
          end
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{name}(value=nil)
              self.#{name} = value if value
              #{name}_without_class_writer
            end
          RUBY
        end
        
        def configure
          yield self
        end
      end

    end
  end
end

