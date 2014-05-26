module Puppet::Parser::Functions

  newfunction(:tp_lookup, :type => :rvalue, :doc => "Looks for tp   data. Usage:
  $tp_packages=tp_lookup($title,'packages')
  ") do |args|
  unless args.length == 2
    raise Puppet::ParseError, ("tp_lookup(): wrong number of arguments (#{args.length}; must be 2)")
  end

  # TODO: Make this function honour the expected hierarchy ( such as in data/hiera.yaml )
  # TODO: Support alternative merge behaviours

  app = args[0]
  res = args[1]
  key = app + "::" + res
  tpmod = Puppet::Module.find("tp", compiler.environment.to_s).path
  yamlfile = tpmod + "/data/" + app + "/default.yaml"

  YAML::load(File.open(yamlfile))[key]
  end
end
