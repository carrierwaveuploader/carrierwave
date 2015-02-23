require "carrierwave/storage/abstract"
require "carrierwave/storage/file"

begin
  require "fog/core"
rescue LoadError
  require "fog" unless defined?(::Fog)
end

require "carrierwave/storage/fog" if defined?(Fog)
