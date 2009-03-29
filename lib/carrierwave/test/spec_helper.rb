module CarrierWave
  module Test
    module SpecHelper

      class BeIdenticalTo
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

      class HavePermissions
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

      class BeNoLargerThan
        def initialize(width, height)
          @width, @height = width, height
        end

        def matches?(actual)
          @actual = actual
          # Satisfy expectation here. Return false or raise an error if it's not met.
          require 'RMagick'
          img = ::Magick::Image.read(@actual.path).first
          @actual_width = img.columns
          @actual_height = img.rows
          @actual_width <= @width && @actual_height <= @height
        end

        def failure_message
          "expected #{@actual.inspect} to be no larger than #{@width} by #{@height}, but it was #{@actual_height} by #{@actual_width}."
        end

        def negative_failure_message
          "expected #{@actual.inspect} to be larger than #{@width} by #{@height}, but it wasn't."
        end
      end

      def be_no_larger_than(width, height)
        BeNoLargerThan.new(width, height)
      end

      class HaveDimensions
        def initialize(width, height)
          @width, @height = width, height
        end

        def matches?(actual)
          @actual = actual
          # Satisfy expectation here. Return false or raise an error if it's not met.
          require 'RMagick'
          img = ::Magick::Image.read(@actual.path).first
          @actual_width = img.columns
          @actual_height = img.rows
          @actual_width == @width && @actual_height == @height
        end

        def failure_message
          "expected #{@actual.inspect} to have an exact size of #{@width} by #{@height}, but it was #{@actual_height} by #{@actual_width}."
        end

        def negative_failure_message
          "expected #{@actual.inspect} not to have an exact size of #{@width} by #{@height}, but it did."
        end
      end

      def have_dimensions(width, height)
        HaveDimensions.new(width, height)
      end
      
    end # SpecHelper
  end # Test
end # CarrierWave