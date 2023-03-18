require 'active_support'

module CarrierWave
  module Uploader
    module Dimension
      extend ActiveSupport::Concern

      included do
        before :cache, :check_dimensions!
      end

      ##
      # Override this method in your uploader to provide a Range of width which
      # are allowed to be uploaded.
      # === Returns
      #
      # [NilClass, Range] a width range which are permitted to be uploaded
      #
      # === Examples
      #
      #     def width_range
      #       1000..2000
      #     end
      #
      def width_range; end

      ##
      # Override this method in your uploader to provide a Range of height which
      # are allowed to be uploaded.
      # === Returns
      #
      # [NilClass, Range] a height range which are permitted to be uploaded
      #
      # === Examples
      #
      #     def height_range
      #       1000..
      #     end
      #
      def height_range; end

    private

      def check_dimensions!(new_file)
        # NOTE: Skip the check for resized images
        return if version_name.present?
        return unless width_range || height_range

        unless respond_to?(:width) || respond_to?(:height)
          raise 'You need to include one of CarrierWave::MiniMagick, CarrierWave::RMagick, or CarrierWave::Vips to perform image dimension validation'
        end

        if width_range&.begin && width < width_range.begin
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.min_width_error", :min_width => ActiveSupport::NumberHelper.number_to_delimited(width_range.begin))
        elsif width_range&.end && width > width_range.end
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.max_width_error", :max_width => ActiveSupport::NumberHelper.number_to_delimited(width_range.end))
        elsif height_range&.begin && height < height_range.begin
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.min_height_error", :min_height => ActiveSupport::NumberHelper.number_to_delimited(height_range.begin))
        elsif height_range&.end && height > height_range.end
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.max_height_error", :max_height => ActiveSupport::NumberHelper.number_to_delimited(height_range.end))
        end
      end

    end # Dimension
  end # Uploader
end # CarrierWave
