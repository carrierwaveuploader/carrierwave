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

            # Treat :convert specially, since it should trigger the file extension change
            force_extension processor_args if processor == :convert
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
            ensure_convert_condition_is_recoverable(condition, condition_type) if method == :convert && condition

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

      # The condition decides whether the conversion takes place, so it decides the
      # extension too. It is evaluated against the filename alone, which is all that
      # is known when a stored file is being located again.
      def convert_applies_to?(filename)
        _, _, condition, condition_type = self.class.processors.detect { |method,| method == :convert }
        return true unless condition

        evaluate_convert_condition(condition, condition_type, CarrierWave::FileReference.new(filename))
      end

      def evaluate_convert_condition(condition, condition_type, file)
        result =
          if condition.respond_to?(:call)
            condition.call(self, :method => :convert, :file => file)
          else
            send(condition, file)
          end
        condition_type == :unless ? !result : !!result
      end

      def ensure_convert_condition_is_recoverable(condition, condition_type)
        from_file = evaluate_convert_condition(condition, condition_type, file)
        from_name = begin
          evaluate_convert_condition(condition, condition_type, CarrierWave::FileReference.new(original_filename))
        rescue CarrierWave::FileUnavailable
          :unavailable
        end
        return if from_file == from_name

        raise CarrierWave::ProcessingError, "The condition given to `process convert:` answered #{from_file.inspect} for the file itself but #{from_name.inspect} from its name #{original_filename.inspect} alone. " \
          "It has to be answerable from the filename, so that the resulting file extension can be worked out again when the file is retrieved."
      end

      def forcing_extension(filename)
        if force_extension && filename && convert_applies_to?(filename)
          Pathname.new(filename).sub_ext(".#{force_extension.to_s.delete_prefix('.')}").to_s
        else
          filename
        end
      end
    end # Processing
  end # Uploader
end # CarrierWave
