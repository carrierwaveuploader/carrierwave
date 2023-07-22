require "active_support/core_ext/object/deep_dup"

module CarrierWave
  module Uploader
    module Versions
      class Builder
        def initialize(name)
          @name = name
          @options = {}
          @blocks = []
          @klass = nil
        end

        def configure(options, &block)
          @options.merge!(options)
          @blocks << block if block
          @klass = nil
        end

        def build(superclass)
          return @klass if @klass
          @klass = Class.new(superclass)
          superclass.const_set("#{@name.to_s.camelize}VersionUploader", @klass)

          @klass.version_names += [@name]
          @klass.versions = {}
          @klass.processors = []
          @klass.version_options = @options
          @klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            # Define the enable_processing method for versions so they get the
            # value from the parent class unless explicitly overwritten
            def self.enable_processing(value=nil)
              self.enable_processing = value if value
              if defined?(@enable_processing) && !@enable_processing.nil?
                @enable_processing
              else
                superclass.enable_processing
              end
            end

            # Regardless of what is set in the parent uploader, do not enforce the
            # move_to_cache config option on versions because it moves the original
            # file to the version's target file.
            #
            # If you want to enforce this setting on versions, override this method
            # in each version:
            #
            # version :thumb do
            #   def move_to_cache
            #     true
            #   end
            # end
            #
            def move_to_cache
              false
            end

            # Need to rely on the parent version's identifier, as versions don't have its own one.
            def identifier
              parent_version.identifier
            end
          RUBY
          @blocks.each { |block| @klass.class_eval(&block) }
          @klass
        end

        def deep_dup
          other = dup
          other.instance_variable_set(:@blocks, @blocks.dup)
          other
        end

        def method_missing(name, *args)
          super
        rescue NoMethodError => e
          raise e.exception <<~ERROR
            #{e.message}
            If you're trying to configure a version, do it inside a block like `version(:thumb) { self.#{name} #{args.map(&:inspect).join(', ')} }`.
          ERROR
        end

        def respond_to_missing?(*)
          super
        end
      end

      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        class_attribute :versions, :version_names, :version_options, :instance_reader => false, :instance_writer => false

        self.versions = {}
        self.version_names = []

        attr_accessor :parent_version

        after :cache, :cache_versions!
        after :store, :store_versions!
        after :remove, :remove_versions!
        after :retrieve_from_cache, :retrieve_versions_from_cache!
        after :retrieve_from_store, :retrieve_versions_from_store!

        prepend Module.new {
          def initialize(*)
            super
            @versions = nil
          end
        }
      end

      module ClassMethods

        ##
        # Adds a new version to this uploader
        #
        # === Parameters
        #
        # [name (#to_sym)] name of the version
        # [options (Hash)] optional options hash
        # [&block (Proc)] a block to eval on this version of the uploader
        #
        # === Examples
        #
        #     class MyUploader < CarrierWave::Uploader::Base
        #
        #       version :thumb do
        #         process :scale => [200, 200]
        #       end
        #
        #       version :preview, :if => :image? do
        #         process :scale => [200, 200]
        #       end
        #
        #       version :square, :unless => :invalid_image_type? do
        #         process :scale => [100, 100]
        #       end
        #
        #     end
        #
        def version(name, options = {}, &block)
          name = name.to_sym
          versions[name] ||= Builder.new(name)
          versions[name].configure(options, &block)

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              versions[:#{name}]
            end
          RUBY

          versions[name]
        end

      private

        def inherited(subclass)
          # To prevent subclass version changes affecting superclass versions
          subclass.versions = versions.deep_dup
          super
        end
      end # ClassMethods

      ##
      # Returns a hash mapping the name of each version of the uploader to an instance of it
      #
      # === Returns
      #
      # [Hash{Symbol => CarrierWave::Uploader}] a list of uploader instances
      #
      def versions
        return @versions if @versions
        @versions = {}
        self.class.versions.each do |name, version|
          @versions[name] = version.build(self.class).new(model, mounted_as)
          @versions[name].parent_version = self
        end
        @versions
      end

      ##
      # === Returns
      #
      # [String] the name of this version of the uploader
      #
      def version_name
        self.class.version_names.join('_').to_sym unless self.class.version_names.blank?
      end

      ##
      #
      # === Parameters
      #
      # [name (#to_sym)] name of the version
      #
      # === Returns
      #
      # [Boolean] True when the version exists according to its :if or :unless condition
      #
      def version_exists?(name)
        name = name.to_sym

        return false unless versions.has_key?(name)

        if_condition = versions[name].class.version_options[:if]
        unless_condition = versions[name].class.version_options[:unless]

        if if_condition
          if if_condition.respond_to?(:call)
            if_condition.call(self, :version => name, :file => file)
          else
            send(if_condition, file)
          end
        elsif unless_condition
          if unless_condition.respond_to?(:call)
            !unless_condition.call(self, :version => name, :file => file)
          else
            !send(unless_condition, file)
          end
        else
          true
        end
      end

      ##
      # Copies the parent's cache_id when caching a version file.
      # This behavior is not essential but it makes easier to understand
      # that the cached files are generated by the single upload attempt.
      #
      def cache!(*args)
        self.cache_id = parent_version.cache_id if parent_version

        super
      end

      ##
      # When given a version name as a parameter, will return the url for that version
      # This also works with nested versions.
      # When given a query hash as a parameter, will return the url with signature that contains query params
      # Query hash only works with AWS (S3 storage).
      #
      # === Example
      #
      #     my_uploader.url                 # => /path/to/my/uploader.gif
      #     my_uploader.url(:thumb)         # => /path/to/my/thumb_uploader.gif
      #     my_uploader.url(:thumb, :small) # => /path/to/my/thumb_small_uploader.gif
      #     my_uploader.url(:query => {"response-content-disposition" => "attachment"})
      #     my_uploader.url(:version, :sub_version, :query => {"response-content-disposition" => "attachment"})
      #
      # === Parameters
      #
      # [*args (Symbol)] any number of versions
      # OR/AND
      # [Hash] query params
      #
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url(*args)
        if (version = args.first) && version.respond_to?(:to_sym)
          raise ArgumentError, "Version #{version} doesn't exist!" if versions[version.to_sym].nil?
          # recursively proxy to version
          versions[version.to_sym].url(*args[1..-1])
        elsif args.first
          super(args.first)
        else
          super
        end
      end

      ##
      # Recreate versions and reprocess them. This can be used to recreate
      # versions if their parameters somehow have changed.
      #
      def recreate_versions!(*names)
        # As well as specified versions, we need to reprocess versions
        # that are the source of another version.

        self.cache_id = CarrierWave.generate_cache_id
        derived_versions.each do |name, v|
          v.cache!(file) if names.empty? || !(v.descendant_version_names & names).empty?
        end
        active_versions.each do |name, v|
          v.store! if names.empty? || names.include?(name)
        end
      ensure
        @cache_id = nil
      end

    protected

      def descendant_version_names
        [version_name] + derived_versions.flat_map do |name, version|
          version.descendant_version_names
        end
      end

      def active_versions
        versions.select do |name, uploader|
          version_exists?(name)
        end
      end

    private

      def derived_versions
        active_versions.reject do |name, v|
          v.class.version_options[:from_version]
        end.to_a + active_sibling_versions.select do |name, v|
          v.class.version_options[:from_version] == self.class.version_names.last
        end.to_a
      end

      def active_sibling_versions
        parent_version&.active_versions || []
      end

      def full_filename(for_file)
        [version_name, super(for_file)].compact.join('_')
      end

      def full_original_filename
        [version_name, super].compact.join('_')
      end

      def cache_versions!(new_file)
        derived_versions.each { |name, v| v.cache!(new_file) }
      end

      def store_versions!(new_file)
        active_versions.each { |name, v| v.store!(new_file) }
      end

      def remove_versions!
        versions.each { |name, v| v.remove! }
      end

      def retrieve_versions_from_cache!(cache_name)
        active_versions.each { |name, v| v.retrieve_from_cache!(cache_name) }
      end

      def retrieve_versions_from_store!(identifier)
        active_versions.each { |name, v| v.retrieve_from_store!(identifier) }
      end

    end # Versions
  end # Uploader
end # CarrierWave
