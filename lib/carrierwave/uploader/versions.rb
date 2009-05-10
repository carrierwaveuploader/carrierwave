module CarrierWave
  module Uploader
    module Versions
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

    end # Versions
  end # Uploader
end # CarrierWave