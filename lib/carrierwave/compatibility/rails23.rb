# Stubbing out Rails::Railtie, which is not present in Rails 2.3.
# Any code defined in initializer block will be called immediately.
module CarrierWave
  class Rails::Railtie
    def self.initializer *args
      yield
    end
  end
end

$:.unshift(File.join(File.dirname(__FILE__), 'rails23'))
