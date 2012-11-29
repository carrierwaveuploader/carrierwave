require "carrierwave/storage/abstract"
require "carrierwave/storage/file"

begin
  require "fog"
rescue LoadError
end

require "carrierwave/storage/fog" if defined?(Fog)
