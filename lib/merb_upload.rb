# make sure we're running inside Merb
if defined?(Merb::Plugins)

  require 'fileutils'

  # Merb gives you a Merb::Plugins.config hash...feel free to put your stuff in your piece of it
  Merb::Plugins.config[:merb_upload] ||= {}
  Merb::Plugins.config[:merb_upload][:storage] ||= :file
  Merb::Plugins.config[:merb_upload][:store_dir] ||= Merb.root / 'public' / 'uploads'
  Merb::Plugins.config[:merb_upload][:tmp_dir] ||= Merb.root / 'public' / 'uploads' / 'tmp'
  
  dir = File.dirname(__FILE__) / 'merb_upload'
  require dir / 'sanitized_file'
  require dir / 'uploader'

end