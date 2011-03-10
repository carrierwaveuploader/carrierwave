# encoding: utf-8

require 'spec_helper'

for credential in FOG_CREDENTIALS
  fog_tests(credential)
end
