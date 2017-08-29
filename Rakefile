require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-syntax/tasks/puppet-syntax'

# Blacksmith
begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
  puts "Blacksmith needed only to push to the Forge"
end
