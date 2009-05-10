module CarrierWave
  module Uploader
    module Versions

      setup do
        after :cache, :cache_versions!
      end

      module ClassMethods

        def version_names
          @version_names ||= []
        end

        ##
        # Adds a new version to this uploader
        #
        # === Parameters
        #
        # [name (#to_sym)] name of the version
        # [&block (Proc)] a block to eval on this version of the uploader
        #
        def version(name, &block)
          name = name.to_sym
          unless versions[name]
            versions[name] = Class.new(self)
            versions[name].version_names.push(*version_names)
            versions[name].version_names.push(name)
            class_eval <<-RUBY
              def #{name}
                versions[:#{name}]
              end
            RUBY
          end
          versions[name].class_eval(&block) if block
          versions[name]
        end

        ##
        # === Returns
        #
        # [Hash{Symbol => Class}] a list of versions available for this uploader
        #
        def versions
          @versions ||= {}
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
        self.class.versions.each do |name, klass|
          @versions[name] = klass.new(model, mounted_as)
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
      # When given a version name as a parameter, will return the url for that version
      # This also works with nested versions.
      #
      # === Example
      #
      #     my_uploader.url                 # => /path/to/my/uploader.gif
      #     my_uploader.url(:thumb)         # => /path/to/my/thumb_uploader.gif
      #     my_uploader.url(:thumb, :small) # => /path/to/my/thumb_small_uploader.gif
      #
      # === Parameters
      #
      # [*args (Symbol)] any number of versions
      #
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url(*args)
        if(args.first)
          raise ArgumentError, "Version #{args.first} doesn't exist!" if versions[args.first.to_sym].nil?
          # recursively proxy to version
          versions[args.first.to_sym].url(*args[1..-1])
        else
          super()
        end
      end

    private
    
      def cache_versions!(new_file)
        versions.each do |name, v|
          v.send(:cache_id=, cache_id)
          v.cache!(new_file)
        end
      end

    end # Versions
  end # Uploader
end # CarrierWave