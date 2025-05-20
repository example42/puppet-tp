
module Puppet::Parser::Functions

  newfunction(:tp_lookup, :type => :rvalue, :doc => "
  Looks for tp data. Usage:
  $tp_settings=tp_lookup($title,'settings','site',deep_merge')
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
        function_notice(["No tinydata found for: #{app} in #{hiera_file_path}. Trying to install package #{app}"])
        default_fallback = true
        hiera_file_path  = mp.path + '/data/default/hiera.yaml'
      end

      hiera_file = File.open(hiera_file_path)
      hiera = YAML::load(hiera_file)
      if lookupvar("upstream_repo")
        repo = 'upstream'
      elsif lookupvar("repo")
        repo = lookupvar("repo")
      else
        repo = ''
      end

      os = lookupvar("::os")

      model = {
        :title => app,
        :osfamily => os['family'],
        :operatingsystem => os['name'],
        :operatingsystemmajrelease => os['release']['major'],
        :operatingsystemrelease => os['release']['full'],
        :repo => repo,
      }

      hiera[:hierarchy].reverse!.each { | p |
        conf_file_path = mp.path + '/data/' + p % model + '.yaml'

        if File.exist?(conf_file_path)
          conf_file = File.open(conf_file_path)
          got_value = YAML::load(conf_file)

          if res == 'settings'
            got_value = got_value.include?(key) ? got_value[key] : got_value['default::settings']
          else
            got_value = got_value.include?(key) ? got_value[key] : {}
          end

          unless got_value.nil?
            value = function_deep_merge([value,got_value]) if look=='deep_merge'
            value.merge!(got_value) if look=='merge'
            value=got_value if look=='direct'
          end
          conf_file.close
        end
      }
      hiera_file.close

      value.merge!({'package_name' => app}) if default_fallback

    else
      raise(Puppet::ParseError, "Could not find module #{datamodule} in environment #{compiler.environment}")
    end

    return value

  end
end
