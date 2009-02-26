require "image_science"

module Stapler
    module ImageScience
      
      # Resize the image so that it will not exceed the dimensions passed
      # via geometry, geometry should be a string, formatted like '200x100' where
      # the first number is the height and the second is the width
      def resize!( geometry )
        ::ImageScience.with_image(self.current_path) do |img|
          width, height = extract_dimensions(img.width, img.height, geometry)
          img.resize( width, height ) do |file|
            file.save( self.current_path )
          end
        end
      end

      # Resize and crop the image so that it will have the exact dimensions passed
      # via geometry, geometry should be a string, formatted like '200x100' where
      # the first number is the height and the second is the width
      def crop_resized!( geometry )
        ::ImageScience.with_image(self.current_path) do |img|
          new_width, new_height = geometry.split('x').map{|i| i.to_i }

          width, height = extract_dimensions_for_crop(img.width, img.height, geometry)
          x_offset, y_offset = extract_placement_for_crop(width, height, geometry)

          img.resize( width, height ) do |i2|

            i2.with_crop( x_offset, y_offset, new_width + x_offset, new_height + y_offset) do |file|
              file.save( self.current_path )
            end
          end
        end
      end

      private

      def extract_dimensions(width, height, new_geometry, type = :resize)
        new_width, new_height = convert_geometry(new_geometry)

        aspect_ratio = width.to_f / height.to_f
        new_aspect_ratio = new_width / new_height

        if (new_aspect_ratio > aspect_ratio) ^ ( type == :crop )  # Image is too wide, the caret is the XOR operator
          new_width, new_height = [ (new_height * aspect_ratio), new_height]
        else #Image is too narrow
          new_width, new_height = [ new_width, (new_width / aspect_ratio)]
        end

        [new_width, new_height].collect! { |v| v.round }
      end

      def extract_dimensions_for_crop(width, height, new_geometry)
        extract_dimensions(width, height, new_geometry, :crop)
      end

      def extract_placement_for_crop(width, height, new_geometry)
        new_width, new_height = convert_geometry(new_geometry)
        x_offset = (width / 2.0) - (new_width / 2.0)
        y_offset = (height / 2.0) - (new_height / 2.0)
        [x_offset, y_offset].collect! { |v| v.round }
      end

      def convert_geometry(geometry)
        geometry.split('x').map{|i| i.to_f }      
      end

  end
end