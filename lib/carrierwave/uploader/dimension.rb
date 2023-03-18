require 'active_support'

module CarrierWave
  module Uploader
    module Dimension
      extend ActiveSupport::Concern

      included do
        before :cache, :check_dimensions!
      end

      ##
      # Override this method in your uploader to provide a tuple of
      # width Range and height Range which are allowed to be uploaded.
      # === Returns
      #
      # [NilClass, [Range, Range]]
      # width range and height range which are permitted to be uploaded
      #
      # === Examples
      #
      #     def dimension_ranges
      #       [1000..2000, 1000..]
      #     end
      #
      def dimension_ranges; end

      private

      def check_dimensions!(new_file)
        # NOTE: Skip the check for resized images
        return if version_name.present?

        expected_dimension_ranges = dimension_ranges
        return unless expected_dimension_ranges.try(:all?) { |v| v.is_a?(::Range) }

        unless respond_to?(:width) || respond_to?(:height)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.no_processing_module_error")
        end

        expected_width_range = expected_dimension_ranges[0]
        expected_height_range = expected_dimension_ranges[1]
        if expected_width_range.begin && width < expected_width_range.begin
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.min_width_error", :min_width => ActiveSupport::NumberHelper.number_to_delimited(expected_width_range.begin))
        elsif expected_width_range.end && width > expected_width_range.end
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.max_width_error", :max_width => ActiveSupport::NumberHelper.number_to_delimited(expected_width_range.end))
        elsif expected_height_range.begin && height < expected_height_range.begin
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.min_height_error", :min_height => ActiveSupport::NumberHelper.number_to_delimited(expected_height_range.begin))
        elsif expected_height_range.end && height > expected_height_range.end
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.max_height_error", :max_height => ActiveSupport::NumberHelper.number_to_delimited(expected_height_range.end))
        end
      end

    end # Dimension
  end # Uploader
end # CarrierWave
