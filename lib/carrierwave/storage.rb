require "carrierwave/storage/abstract"
require "carrierwave/storage/file"

%w(aws google openstack rackspace).each do |fog_dependency|
  begin
    require "fog/#{fog_dependency}"
  rescue LoadError
  end
end

require "carrierwave/storage/fog" if defined?(Fog)
