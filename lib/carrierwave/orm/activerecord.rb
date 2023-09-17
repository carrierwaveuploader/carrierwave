require 'active_record'
require 'carrierwave/validations/active_model'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount

  private

    def mount_base(column, uploader=nil, options={}, &block)
      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute
      public :read_uploader
      public :write_uploader

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
      validates_download_of column if uploader_option(column.to_sym, :validate_download)

      after_save :"store_#{column}!"
      before_save :"write_#{column}_identifier"
      after_commit :"remove_#{column}!", :on => :destroy
      after_commit :"mark_remove_#{column}_false", :on => :update

      after_commit :"reset_previous_changes_for_#{column}"
      after_commit :"remove_previously_stored_#{column}", :on => :update
      after_rollback :"remove_rolled_back_#{column}"

      mod = Module.new
      prepend mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        # Reset cached mounter on record reload
        def reload(*)
          @_mounters = nil
          super
        end

        # Reset cached mounter on record dup
        def initialize_dup(other)
          old_uploaders = _mounter(:"#{column}").uploaders
          super
          @_mounters[:"#{column}"] = nil
          # The attribute needs to be cleared to prevent it from picked up as identifier
          write_attribute(_mounter(:#{column}).serialization_column, nil)
          _mounter(:"#{column}").cache(old_uploaders)
        end

        def write_#{column}_identifier
          return unless has_attribute?(_mounter(:#{column}).serialization_column)
          super
        end
      RUBY
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::ActiveRecord
