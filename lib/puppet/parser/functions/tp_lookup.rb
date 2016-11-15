
module Puppet::Parser::Functions

  newfunction(:tp_lookup, :type => :rvalue, :doc => "
  Looks for tp data. Usage:
  $tp_settings=tp_lookup($title,'settings','site','merge')
  ") do |args|
    unless args.length >= 3
      raise Puppet::ParseError, ("tp_lookup(): wrong number of arguments (#{args.length}; must be 2 or 3)")
    end

    app = args[0]
    res = args[1]
    datamodule = args[2]
    args[3].to_s.length!=0 ? look = args[3] : look = 'direct'
    key = app + "::" + res

    value = { }

    if mp = Puppet::Module.find(datamodule, compiler.environment.to_s)
      
      hiera_file_path  = mp.path + '/data/' + app + '/hiera.yaml'

      unless File.exist?(hiera_file_path)
        raise Puppet::ParseError, ("I can't find data for: #{app}. Looking in file: #{hiera_file_path}. Using this data module: #{datamodule}")
      end

      hiera = YAML::load(File.open(hiera_file_path))
      model = {
        :title                     => app,
        :osfamily                  => lookupvar("::osfamily"),
        :operatingsystem           => lookupvar("::operatingsystem"),
        :operatingsystemmajrelease => lookupvar("::operatingsystemmajrelease"),
        :operatingsystemrelease    => lookupvar("::operatingsystemrelease"),
        :repo                      => exist?("repo") && lookupvar("repo"),
      }
       
      hiera[:hierarchy].reverse!.each { | p |
        conf_file_path = mp.path + '/data/' + p % model + '.yaml'

        if File.exist?(conf_file_path)
          got_value = YAML::load(File.open(conf_file_path))

          got_value = got_value.include?(key) ? got_value[key] : got_value['default::settings']

          unless got_value.nil?
            value = function_deep_merge([value,got_value]) if look=='deep_merge'
            value.merge!(got_value) if look=='merge'
            value=got_value if look=='direct'
          end
        end
      }

    else
      raise(Puppet::ParseError, "Could not find module #{datamodule} in environment #{compiler.environment}")
    end

    return value

  end
end
