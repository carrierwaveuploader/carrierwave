require "carrierwave/storage/abstract"
require "carrierwave/storage/file"

begin
  require "fog/core"
rescue LoadError
  begin
    require "fog" unless defined?(::Fog)
  rescue LoadError
  end
end

require "carrierwave/storage/fog" if defined?(Fog)
