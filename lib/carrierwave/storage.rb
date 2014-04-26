require "carrierwave/storage/abstract"
require "carrierwave/storage/file"

begin
  require "fog" unless defined?(::Fog)
rescue LoadError
end

require "carrierwave/storage/fog" if defined?(Fog)
