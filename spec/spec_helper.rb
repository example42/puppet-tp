require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'
if ENV['PARSER'] == 'future'
  RSpec.configure do |c|
    c.parser = 'future'
  end
end
Coveralls.wear!
