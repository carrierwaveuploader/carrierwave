require 'rmagick'

module Stapler
    module RMagick
      
      # Convert the image to format
      def convert(format)
        manipulate! do |img|
          img.format = format.to_s.upcase
          img
        end
      end

      # Resize the image so that it will not exceed the dimensions passed
      def resize(height, width)
        geometry = "#{height}x#{width}"
        manipulate! do |img|
          img.change_geometry( geometry ) do |c, r, i|
            i.resize(c,r)
          end
        end
      end

      # Resize and crop the image so that it will have the exact dimensions passed
      def crop_resized(height, width)
        manipulate! do |img|
          img.crop_resized(height,width)
        end
      end

      # Manipulate the image with rmagick
      def manipulate!
        image = ::Magick::Image.read(self.current_path)

        if image.size > 1
          list = ::Magick::ImageList.new
          image.each do |frame|
            list << yield( frame )
          end
          list.write(self.current_path)
        else
          yield( image.first ).write(self.current_path)
        end
      rescue ::Magick::ImageMagickError => e
        raise Stapler::ProcessingError.new("Failed to manipulate with rmagick, maybe it is not an image? Original Error: #{e}")
      end      
      
  end
end