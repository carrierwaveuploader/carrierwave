class <%= class_name %>Uploader

  include CarrierWave::Uploader
  
  # Include RMagick or ImageScience support
  #     include CarrierWave::RMagick
  #     include CarrierWave::ImageScience
  
  # Choose what kind of storage to use for this uploader
  storage :file
  #     storage :s3
  
  # Process files as they are uploaded.
  #     process :scale => [200, 300]
  # 
  #     def scale(width, height)
  #       # do something
  #     end 
  
  # Create different versions of your uploaded files
  #     version :thumb do
  #       process :scale => [50, 50]
  #     end
  
  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  #     def extension_white_list
  #       %w(jpg jpeg gif png)
  #     end
  
  # Override the filename of the uploaded files
  #     def filename
  #       "something.jpg"
  #     end
  
  # Override the directory where uploaded files will be stored
  #     def store_dir
  #       "something"
  #     end
  
end