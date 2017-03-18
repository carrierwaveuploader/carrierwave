require 'active_record'
require 'carrierwave/validations/active_model'
require 'hana'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      super

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def remote_#{column}_url=(url)
          column = _mounter(:#{column}).serialization_column
          __send__(:"\#{column}_will_change!")
          super
        end
      RUBY
    end

    ##
    # See +CarrierWave::Mount#mount_uploaders+ for documentation
    #
    def mount_uploaders(column, uploader=nil, options={}, &block)
      super

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def remote_#{column}_urls=(url)
          column = _mounter(:#{column}).serialization_column
          __send__(:"\#{column}_will_change!")
          super
        end
      RUBY
    end

  private

    def mount_base(column, uploader=nil, options={}, &block)
      super

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
      validates_download_of column if uploader_option(column.to_sym, :validate_download)

      after_save :"store_#{column}!"
      before_save :"write_#{column}_identifier"
      after_commit :"remove_#{column}!", :on => :destroy
      after_commit :"mark_remove_#{column}_false", :on => :update

      after_save :"store_previous_changes_for_#{column}"
      after_commit :"remove_previously_stored_#{column}", :on => :update

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column
          if !(new_file.blank? && __send__(:#{column}).blank?)
            __send__(:"\#{column}_will_change!")
          end

          super
        end

        def remove_#{column}=(value)
          column = _mounter(:#{column}).serialization_column
          __send__(:"\#{column}_will_change!")
          super
        end

        def remove_#{column}!
          self.remove_#{column} = true
          write_#{column}_identifier
          self.remove_#{column} = false
          super
        end

        # Reset cached mounter on record reload
        def reload(*)
          @_mounters = nil
          super
        end

        # Reset cached mounter on record dup
        def initialize_dup(other)
          @_mounters = nil
          super
        end

        def read_uploader(serialization_column)
          attribute = read_attribute(serialization_column)

          if attribute.is_a? Hash
            mount_path = _mounter(:#{column}).mount_path.to_s
            pointer = ::Hana::Pointer.new mount_path

            pointer.eval(attribute)
          else
            attribute
          end
        end

        def write_uploader(serialization_column, identifier)
          mount_path = _mounter(:#{column}).mount_path.to_s

          if mount_path.blank?
            write_attribute(serialization_column, identifier)
          else
            attribute = read_attribute(serialization_column) || {}

            parent_path = mount_path.split("/")[0..-2].reject(&:blank?)
            attribute = create_path_in_hash(attribute, parent_path)
            attribute = Hana::Patch.new([{ 'op' => 'replace', 'path' => mount_path, 'value' => identifier }]).apply(attribute)

            write_attribute(serialization_column, attribute)
          end
        end

        def create_path_in_hash(attribute, path, index=0)
          if path.count > index
            segment = path[index]
            attribute[segment] ||= {}
            raise CarrierWave::InvalidParameter.new("Attempted to provide a mount_path that has one or more invalid path segments.") unless attribute[segment].is_a?(Hash) || !attribute[segment]
            attribute[segment] = create_path_in_hash(attribute[segment], path, index + 1)
          end
          attribute
        end
      RUBY
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::ActiveRecord
