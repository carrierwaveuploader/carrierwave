if defined?(Rails) && Rails::VERSION::MAJOR < 3
  require 'carrierwave/compatibility/rails23'
end

require 'carrierwave'
