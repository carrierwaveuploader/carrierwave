# encoding: utf-8

require 'active_record'
require 'carrierwave/validations/active_model'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount
    
    def serialized_uploaders
      @serialized_uploaders ||= {}
    end
    
    def serialized_uploader?(column)
      serialized_uploaders.key?(column) && serialized_attributes.key?(serialized_uploaders[column].to_s)
    end

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      serialize_to = options.delete :serialize_to
      if serialize_to
        serialized_uploaders[column] = serialize_to 
        class_eval <<-RUBY, __FILE__, __LINE__+1
          def #{column}_will_change!
            #{serialize_to}_will_change!
            @#{column}_changed = true
          end

          def #{column}_changed?
            @#{column}_changed
          end
        RUBY
      end
      
      super

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
      validates_download_of column if uploader_option(column.to_sym, :validate_download)

      after_save :"store_#{column}!"
      before_save :"write_#{column}_identifier"
      after_commit :"remove_#{column}!", :on => :destroy
      before_update :"store_previous_model_for_#{column}"
      after_save :"remove_previously_stored_#{column}"
      
      unless @evaluated
        class_eval <<-RUBY, __FILE__, __LINE__+1
          def write_uploader(column, identifier)
            if self.class.serialized_uploader?(column)
              serialized_field = self.send self.class.serialized_uploaders[column]
              serialized_field[column.to_s] = identifier
            else
              write_attribute column, identifier
            end
          end

          def read_uploader(column)
            if self.class.serialized_uploader?(column)
              serialized_field = self.send self.class.serialized_uploaders[column]
              serialized_field[column.to_s]
            else
              read_attribute column
            end
          end

          def serializable_hash(options=nil)
            hash = {}

            except = options && options[:except] && Array.wrap(options[:except]).map(&:to_s)
            only   = options && options[:only]   && Array.wrap(options[:only]).map(&:to_s)

            self.class.uploaders.each do |column, uploader|
              if (!only && !except) || (only && only.include?(column.to_s)) || (except && !except.include?(column.to_s))
                hash[column.to_s] = _mounter(column).uploader.serializable_hash
              end
            end
            super(options).merge(hash)
          end
        RUBY
        
        @evaluated = true
      end

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column
          send(:"\#{column}_will_change!")
          super
        end

        def remote_#{column}_url=(url)
          column = _mounter(:#{column}).serialization_column
          send(:"\#{column}_will_change!")
          super
        end

        def remove_#{column}!
          super
          _mounter(:#{column}).remove = true
          _mounter(:#{column}).write_identifier
        end
      RUBY

    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::ActiveRecord