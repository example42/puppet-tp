
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



    if mp = Puppet::Module.find("tp", compiler.environment.to_s)
      hiera_file_path  = mp.path + '/data/hiera.yaml'
      hiera = YAML::load(File.open(hiera_file_path))

      model = {
          title: app,
          osfamily: lookupvar('::osfamily'),
          operatingsystem: lookupvar('::operatingsystem'),
          operatingsystemrelease: lookupvar('::operatingsystemrelease')
      }

      hiera[:hierarchy].each { | p |
        conf_file_path = mp.path + '/data/' + p % model + '.yaml'

        if File.exist?(conf_file_path)
          puts "Loading file: " + conf_file_path
          value = YAML::load(File.open(conf_file_path))[key]

          unless value.nil?
            return value
          end
        end
      }

    else
      raise(Puppet::ParseError, "Could not find module tp in environment #{compiler.environment}")
    end
  end
end
