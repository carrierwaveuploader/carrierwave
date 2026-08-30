module CarrierWave
  module Uploader
    module Processing
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        class_attribute :processors, :instance_writer => false
        self.processors = []

        class_attribute :convert_condition_checked

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

            # Treat :convert specially, since it should trigger the file extension change.
            # A conditional one is settled per file by #process!, so it is left alone here.
            force_extension processor_args if processor == :convert && !condition
          end
        end

        ##
        # === Returns
        #
        # [Boolean] Whether the file is converted only on a condition, which makes the
        #   resulting file extension unknowable without a record of it
        #
        def conditional_convert?
          processors.any? { |method, _, condition, _| method == :convert && condition }
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

            if method == :convert
              self.force_extension = args
              show_warning_when_the_extension_is_unrecordable if condition
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

      # The mount raises over this, but it cannot see a version's processors, as those
      # are only built once a version is used
      def show_warning_when_the_extension_is_unrecordable
        return if self.class.convert_condition_checked
        self.class.convert_condition_checked = true
        return if metadata_recorded?

        warn <<~MESSAGE
          [WARNING] #{self.class.name || 'An uploader'} converts the file conditionally, so the extension of the stored file cannot be worked out again on retrieval, and has to be recorded.
          Give the mount a `metadata_column` to record it in. Note that a conditional conversion within a version doesn't survive a form redisplay either way, as a version's cached file is named after the parent's cache name: https://github.com/carrierwaveuploader/carrierwave#recording-what-was-stored
        MESSAGE
      end

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
