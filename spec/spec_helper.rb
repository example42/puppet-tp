require 'puppetlabs_spec_helper/module_spec_helper'
require 'simplecov'
require 'coveralls'
if ENV['PARSER'] == 'future'
  RSpec.configure do |c|
    c.parser = 'future'
  end
end
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec/fixtures/modules/'
end

