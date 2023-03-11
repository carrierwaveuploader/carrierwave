module CarrierWave
  module Uploader
    module Processing
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        class_attribute :processors, :instance_writer => false
        self.processors = []

        before :cache, :process!
      end

      module ClassMethods

        ##
        # Adds a processor callback which applies operations as a file is uploaded.
        # The argument may be the name of any method of the uploader, expressed as a symbol,
        # or a list of such methods, or a hash where the key is a method and the value is
        # an array of arguments to call the method with. Also accepts an :if or :unless condition
        #
        # === Parameters
        #
        # args (*Symbol, Hash{Symbol => Array[]})
        #
        # === Examples
        #
        #     class MyUploader < CarrierWave::Uploader::Base
        #
        #       process :sepiatone, :vignette
        #       process :scale => [200, 200]
        #       process :scale => [200, 200], :if => :image?
        #       process :scale => [200, 200], :unless => :disallowed_image_type?
        #       process :sepiatone, :if => :image?
        #
        #       def sepiatone
        #         ...
        #       end
        #
        #       def vignette
        #         ...
        #       end
        #
        #       def scale(height, width)
        #         ...
        #       end
        #
        #       def image?
        #         ...
        #       end
        #
        #       def disallowed_image_type?
        #         ...
        #       end
        #
        #     end
        #
        def process(*args)
          new_processors = args.inject({}) do |hash, arg|
            arg = { arg => [] } unless arg.is_a?(Hash)
            hash.merge!(arg)
          end

          condition_type = new_processors.keys.detect { |key| [:if, :unless].include?(key) }
          condition = new_processors.delete(:if) || new_processors.delete(:unless)
          new_processors.each do |processor, processor_args|
            self.processors += [[processor, processor_args, condition, condition_type]]

            if processor == :convert
              # Treat :convert specially, since it should trigger the file extension change
              force_extension processor_args
            end
          end
        end
      end # ClassMethods

      ##
      # Apply all process callbacks added through CarrierWave.process
      #
      def process!(new_file=nil)
        return unless enable_processing

        with_callbacks(:process, new_file) do
          self.class.processors.each do |method, args, condition, condition_type|
            if condition && condition_type == :if
              if condition.respond_to?(:call)
                next unless condition.call(self, :args => args, :method => method, :file => new_file)
              else
                next unless self.send(condition, new_file)
              end
            elsif condition && condition_type == :unless
              if condition.respond_to?(:call)
                next if condition.call(self, :args => args, :method => method, :file => new_file)
              elsif self.send(condition, new_file)
                next
              end
            end

            if args.is_a? Array
              kwargs, args = args.partition { |arg| arg.is_a? Hash }
            end

            if kwargs.present?
              kwargs = kwargs.reduce(:merge)
              self.send(method, *args, **kwargs)
            else
              self.send(method, *args)
            end
          end
        end
      end

    private

      def forcing_extension(filename)
        if force_extension && filename
          Pathname.new(filename).sub_ext(".#{force_extension.to_s.delete_prefix('.')}").to_s
        else
          filename
        end
      end
    end # Processing
  end # Uploader
end # CarrierWave
