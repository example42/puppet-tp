#
# = Define: tp::concat
#
define tp::concat (

  $ensure               = present,

  $source               = undef,
  $template             = undef,
  $epp                  = undef,
  $content              = undef,

  $order                = undef,

  $path                 = undef,
  $mode                 = undef,
  $owner                = undef,
  $group                = undef,

  $warn                 = undef,
  $force                = undef,
  $replace              = undef,
  $order                = undef,
  $ensure_newline       = undef,

  $config_file_notify   = true, # If Package[$title] exists, require it
  $config_file_require  = true, # If Service[$title] exists, notify it

  $options_hash         = undef,

  $debug                = false,
  $debug_dir            = '/tmp',

  $data_module          = 'tp',

  ) {

  # Parameters validation
  validate_bool($debug)
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent. WARNING: If set to absent the conf file is removed.')


  # Settings evaluation
  $title_elements = split($title,'::')
  $app = $title_elements[0]
  $fragment = $title_elements[1]
  $settings = tp_lookup($app,'settings',$data_module,'merge')
  $manage_path = tp_pick($path, $settings['config_file_path'])
  $manage_content = tp_content($content, $template, $epp)
  $manage_mode = tp_pick($mode, $settings[config_file_mode])
  $manage_owner = tp_pick($owner, $settings[config_file_owner])
  $manage_group = tp_pick($group, $settings[config_file_group])

  # Set require if package resource is present 
  if defined("Package[${settings[package_name]}]") {
    $package_ref = "Package[${settings[package_name]}]"
  } else {
    $package_ref = undef
  }
  $manage_require = $config_file_require ? {
    ''        => undef,
    false     => undef,
    true      => $package_ref,
    default   => $config_file_require,
  }

  # Set notify if service resource is present 
  if defined("Service[${settings[service_name]}]") {
    $service_ref = "Service[${settings[service_name]}]"
  } else {
    $service_ref = undef
  }
  $manage_notify  = $config_file_notify ? {
    ''        => undef,
    false     => undef,
    true      => $service_ref,
    default   => $config_file_notify,
  }


  # Concat resources
  include concat
  
  if !defined(Concat[$manage_path]) {
    ::concat { $manage_path:
      ensure         => present,
      path           => $manage_path,
      mode           => $manage_mode,
      owner          => $manage_owner,
      group          => $manage_group,
      require        => $manage_require,
      notify         => $manage_notify,
      warn           => $warn,
      force          => $force,
      replace        => $replace,
      ensure_newline => $ensure_newline,
    }
  }

  ::concat::fragment { "${manage_path}_${fragment}":
    ensure  => $ensure,
    source  => $source,
    content => $manage_content,
    target  => $manage_path,
    order   => $order,
  }


  # Debugging
  if $debug == true {
 
    $debug_file_params = "
    concat { ${manage_path}:
      ensure         => present,
      path           => ${manage_path},
      mode           => ${manage_mode},
      owner          => ${manage_owner},
      group          => ${manage_group},
      require        => ${manage_require},
      notify         => ${manage_notify},
      warn           => ${warn},
      force          => ${force},
      replace        => ${replace},
      ensure_newline => ${ensure_newline},
    }

    concat::fragment { \"${manage_path}_${title}\":
      ensure         => ${ensure},
      source         => ${source},
      content        => ${manage_content},
      target         => ${manage_path},
    }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_concat_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_concat_debug_${title}",
    }
  }

}
