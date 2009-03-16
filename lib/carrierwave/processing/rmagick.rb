require 'rmagick'

module CarrierWave

  ##
  # This module simplifies manipulation with RMagick by providing a set
  # of convenient helper methods. If you want to use them, you'll need to
  # require this file:
  #
  #     require 'carrierwave/processing/rmagick'
  #
  # And then include it in your uploader:
  #
  #     MyUploader < CarrierWave::Uploader
  #       include CarrierWave::RMagick
  #     end
  #
  # You can now use the provided helpers:
  #
  #     MyUploader < CarrierWave::Uploader
  #       include CarrierWave::RMagick
  #
  #       process :resize_to_fit => [200, 200]
  #     end
  #
  # Or create your own helpers with the powerful manipulate! method. Check
  # out the RMagick docs at http://www.imagemagick.org/RMagick/doc/ for more
  # info
  #
  #     MyUploader < CarrierWave::Uploader
  #       include CarrierWave::RMagick
  #
  #       process :do_stuff => 10.0
  #
  #       def do_stuff(blur_factor)
  #         manipulate! do |img|
  #           img = img.sepiatone
  #           img = img.auto_orient
  #           img = img.radial_blur(blur_factor)
  #         end
  #       end
  #     end
  #
  module RMagick

    ##
    # Changes the image encoding format to the given format
    #
    # @see http://www.imagemagick.org/RMagick/doc/magick.html#formats
    # @param [#to_s] format an abreviation of the format
    # @yieldparam [Magick::Image] img additional manipulations to perform
    # @example
    #     image.convert(:png)
    #
    def convert(format)
      manipulate! do |img|
        img.format = format.to_s.upcase
        img = yield(img) if block_given?
        img
      end
    end

    ##
    # From the RMagick documentation: "Resize the image to fit within the
    # specified dimensions while retaining the original aspect ratio. The
    # image may be shorter or narrower than specified in the smaller dimension
    # but will not be larger than the specified values."
    #
    # @see http://www.imagemagick.org/RMagick/doc/image3.html#resize_to_fit
    #
    # @param [Integer] width the width to scale the image to
    # @param [Integer] height the height to scale the image to
    # @yieldparam [Magick::Image] img additional manipulations to perform
    #
    def resize_to_fit(width, height)
      manipulate! do |img|
        img.resize_to_fit!(width, height)
        img = yield(img) if block_given?
        img
      end
    end

    alias_method :resize, :resize_to_fit

    ##
    # From the RMagick documentation: "Resize the image to fit within the
    # specified dimensions while retaining the aspect ratio of the original
    # image. If necessary, crop the image in the larger dimension."
    #
    # @see http://www.imagemagick.org/RMagick/doc/image3.html#resize_to_fill
    #
    # @param [Integer] width the width to scale the image to
    # @param [Integer] height the height to scale the image to
    # @yieldparam [Magick::Image] img additional manipulations to perform
    #
    def resize_to_fill(width, height)
      manipulate! do |img|
        img.resize_to_fill!(width, height)
        img = yield(img) if block_given?
        img
      end
    end

    alias_method :crop_resized, :resize_to_fill

    ##
    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. If necessary, will pad the remaining area
    # with the given color, which defaults to transparent (for gif and png,
    # white for jpeg).
    #
    # @param [Integer] width the width to scale the image to
    # @param [Integer] height the height to scale the image to
    # @param [String, :transparent] background the color of the background as a hexcode, like "#ff45de"
    # @param [Magick::GravityType] gravity how to position the image
    # @yieldparam [Magick::Image] img additional manipulations to perform
    #
    def resize_and_pad(width, height, background=:transparent, gravity=::Magick::CenterGravity)
      manipulate! do |img|
        img.resize_to_fit!(width, height)
        new_img = ::Magick::Image.new(width, height)
        if background == :transparent
          new_img = new_img.matte_floodfill(1, 1)
        else
          new_img = new_img.color_floodfill(1, 1, ::Magick::Pixel.from_color(background))
        end
        new_img = new_img.composite(img, gravity, ::Magick::OverCompositeOp)
        new_img = yield(new_img) if block_given?
        new_img
      end
    end

    ##
    # Manipulate the image with RMagick. This method will load up an image
    # and then pass each of its frames to the supplied block. It will then
    # save the image to disk.
    #
    # Note: This method assumes that the object responds to +current_path+.
    # Any class that this is mixed into must have a +current_path+ method.
    # CarrierWave::Uploader does, so you won't need to worry about this in
    # most cases.
    #
    # @yieldparam [Magick::Image] img manipulations to perform
    # @raise [CarrierWave::ProcessingError] if manipulation failed.
    #
    def manipulate!
      image = ::Magick::Image.read(current_path)

      if image.size > 1
        list = ::Magick::ImageList.new
        image.each do |frame|
          list << yield( frame )
        end
        list.write(current_path)
      else
        yield( image.first ).write(current_path)
      end
    rescue ::Magick::ImageMagickError => e
      raise CarrierWave::ProcessingError.new("Failed to manipulate with rmagick, maybe it is not an image? Original Error: #{e}")
    end

  end # RMagick
end # CarrierWave
