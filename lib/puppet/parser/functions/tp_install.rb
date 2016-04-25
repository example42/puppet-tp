# tp_install tries to safely declare duplicated tp::install
# It is derived from stdlib/ensure_resource function
require 'puppet/parser/functions'
Puppet::Parser::Functions.newfunction(:tp_install,
                                      :type => :statement,
                                      :doc => <<-'ENDOFDOC'
Takes the application title and an optional list of parameters.
It declares a tp::install with the given title and parameters.
This function can be called used multiple times with the same application title.
If parameters are used, then you may have a Duplicate declaration: Tp::Install[$app] error.
In such cases try to have the tp_install function with parameters being parsed before the other occurences.

The first argument can be an array of applications to install.
ENDOFDOC
) do |vals|
  title, params = vals
  raise(ArgumentError, 'Must specify an application name') unless title
  params ||= {}

  items = [title].flatten

  items.each do |item|
    Puppet::Parser::Functions.function(:defined_with_params)
    if function_defined_with_params(["tp::install[#{item}]", params])
      Puppet.debug("Resource tp::install[#{item}] with params #{params} not created because it already exists")
    else
      Puppet.debug("Created new resource tp::install[#{item}] with params #{params}")
      Puppet::Parser::Functions.function(:create_resources)
      function_create_resources(['Tp::Install', { item => params }])
    end
  end
end
