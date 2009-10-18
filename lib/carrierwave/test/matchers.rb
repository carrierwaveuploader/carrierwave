# encoding: utf-8

module CarrierWave
  module Test

    ##
    # These are some matchers that can be used in RSpec specs, to simplify the testing
    # of uploaders.
    #
    module Matchers

      class BeIdenticalTo # :nodoc:
        def initialize(expected)
          @expected = expected
        end
        def matches?(actual)
          @actual = actual
          FileUtils.identical?(@actual, @expected)
        end
        def failure_message
          "expected #{@actual.inspect} to be identical to #{@expected.inspect}"
        end
        def negative_failure_message
          "expected #{@actual.inspect} to not be identical to #{@expected.inspect}"
        end
      end

      def be_identical_to(expected)
        BeIdenticalTo.new(expected)
      end

      class HavePermissions # :nodoc:
        def initialize(expected)
          @expected = expected
        end

        def matches?(actual)
          @actual = actual
          # Satisfy expectation here. Return false or raise an error if it's not met.
          (File.stat(@actual.path).mode & 0777) == @expected
        end

        def failure_message
          "expected #{@actual.inspect} to have permissions #{@expected.to_s(8)}, but they were #{(File.stat(@actual.path).mode & 0777).to_s(8)}"
        end

        def negative_failure_message
          "expected #{@actual.inspect} not to have permissions #{@expected.to_s(8)}, but it did"
        end
      end

      def have_permissions(expected)
        HavePermissions.new(expected)
      end

      class BeNoLargerThan # :nodoc:
        def initialize(width, height)
          @width, @height = width, height
        end

        def matches?(actual)
          @actual = actual
          # Satisfy expectation here. Return false or raise an error if it's not met.
          img = ::Magick::Image.read(@actual.current_path).first
          @actual_width = img.columns
          @actual_height = img.rows
          @actual_width <= @width && @actual_height <= @height
        end

        def failure_message
          "expected #{@actual.current_path.inspect} to be no larger than #{@width} by #{@height}, but it was #{@actual_width} by #{@actual_height}."
        end

        def negative_failure_message
          "expected #{@actual.current_path.inspect} to be larger than #{@width} by #{@height}, but it wasn't."
        end
      end

      def be_no_larger_than(width, height)
        load_rmagick
        BeNoLargerThan.new(width, height)
      end

      class HaveDimensions # :nodoc:
        def initialize(width, height)
          @width, @height = width, height
        end

        def matches?(actual)
          @actual = actual
          # Satisfy expectation here. Return false or raise an error if it's not met.
          img = ::Magick::Image.read(@actual.current_path).first
          @actual_width = img.columns
          @actual_height = img.rows
          @actual_width == @width && @actual_height == @height
        end

        def failure_message
          "expected #{@actual.current_path.inspect} to have an exact size of #{@width} by #{@height}, but it was #{@actual_width} by #{@actual_height}."
        end

        def negative_failure_message
          "expected #{@actual.current_path.inspect} not to have an exact size of #{@width} by #{@height}, but it did."
        end
      end

      def have_dimensions(width, height)
        load_rmagick
        HaveDimensions.new(width, height)
      end

    private
    
      def load_rmagick
        unless defined? Magick 
          begin
            require 'rmagick'
          rescue LoadError
            require 'RMagick'
          rescue LoadError
            puts "WARNING: Failed to require rmagick, image processing may fail!"
          end
        end
      end
      
    end # SpecHelper
  end # Test
end # CarrierWave