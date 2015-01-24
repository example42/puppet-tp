#
# = Define: tp::stdmod
#
# This defines reproduces a standard module based
# on a this stdmod standard template
# (https://github.com/stdmod/puppet-skeleton-standard)
#
# The define exposes stdmod compliant parameters for
# standard package, service, configuration setups.
#
define tp::stdmod (

  $package_name              = undef,
  $package_ensure            = 'present',

  $service_name              = undef,
  $service_ensure            = undef,
  $service_enable            = undef,

  $config_file_path          = undef,
  $config_file_replace       = undef,
  $config_file_require       = undef,
  $config_file_notify        = 'default',
  $config_file_source        = undef,
  $config_file_template      = undef,
  $config_file_epp           = undef,
  $config_file_content       = undef,
  $config_file_options_hash  = undef,
  $config_file_owner         = undef,
  $config_file_group         = undef,
  $config_file_mode          = undef,

  $config_dir_path           = undef,
  $config_dir_source         = undef,
  $config_dir_purge          = undef,
  $config_dir_force          = undef,
  $config_dir_recurse        = undef,

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  $debug                     = false,
  $debug_dir                 = '/tmp',

  $data_module               = 'tp',

  ) {

  # Parameters validation
  validate_bool($debug)
  

  # Settings evaluation
  $tp_settings = tp_lookup($title,'settings',$data_module,'merge')
  $user_settings = {
    package_name              => $package_name,
    package_ensure            => $package_ensure,
    service_name              => $service_name,
    service_ensure            => $service_ensure,
    service_enable            => $service_enable,
    config_file_path          => $config_file_path,
    config_file_replace       => $config_file_replace,
    config_file_require       => $config_file_require,
    config_file_notify        => $config_file_notify,
    config_file_owner         => $config_file_owner,
    config_file_group         => $config_file_group,
    config_file_mode          => $config_file_mode,
    config_dir_path           => $config_dir_path,
    config_dir_purge          => $config_dir_purge,
    config_dir_force          => $config_dir_force,
    config_dir_recurse        => $config_dir_recurse,
  }
  $user_settings_clean = delete_undef_values($user_settings)
  $settings = merge($tp_settings,$user_settings_clean)

  $manage_config_file_content = tp_content($config_file_content, $config_file_template, $config_file_epp)
  $manage_config_file_require = "Package[${settings[package_name]}]"
  $manage_config_file_notify  = $config_file_notify ? {
    'default' => "Service[${settings[service_name]}]",
    'undef'   => undef,
    ''        => undef,
    default   => $config_file_notify,
  }

  if $package_ensure == 'absent' {
    $manage_service_enable = undef
    $manage_service_ensure = stopped
    $config_dir_ensure = absent
    $config_file_ensure = absent
  } else {
    $manage_service_enable = $service_enable ? {
      ''      => undef,
      'undef' => undef,
      default => $service_enable,
    }
    $manage_service_ensure = $service_ensure ? {
      ''      => undef,
      'undef' => undef,
      default => $service_ensure,
    }
    $config_dir_ensure = directory
    $config_file_ensure = present
  }


  # Dependency class
  if $dependency_class { include $dependency_class }


  # Resources
  if $settings[package_name] {
    package { $settings[package_name]:
      ensure => $settings[package_ensure],
    }
  }

  if $settings[service_name] {
    service { $settings[service_name]:
      ensure => $settings[service_ensure],
      enable => $settings[service_enable],
    }
  }

  if $config_file_source
  or $manage_config_file_content
  or $config_file_ensure == 'absent' {
    file { $settings[config_file_path]:
      ensure  => $config_file_ensure,
      path    => $settings[config_file_path],
      mode    => $settings[config_file_mode],
      owner   => $settings[config_file_owner],
      group   => $settings[config_file_group],
      source  => $settings[config_file_source],
      content => $manage_config_file_content,
      notify  => $manage_config_file_notify,
      require => $manage_config_file_require,
    }
  }

  if $config_dir_source {
    file { $settings[config_dir_path]:
      ensure  => $config_dir_ensure,
      path    => $settings[config_dir_path],
      source  => $config_dir_source,
      recurse => $settings[config_dir_recurse],
      purge   => $settings[config_dir_purge],
      force   => $settings[config_dir_force],
      notify  => $manage_config_file_notify,
      require => $manage_config_file_require,
    }
  }


  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }


  # Debugging
  if $debug == true {
    $debug_file_params = "
    package { ${settings[package_name]}:
      ensure => ${settings[package_ensure]},
    }

    service { ${settings[service_name]}:
      ensure => ${settings[service_ensure]},
      enable => ${settings[service_enable]},
    } 

    file { ${settings[config_file_path]}:
      ensure  => ${config_file_ensure},
      path    => ${settings[config_file_path]},
      mode    => ${settings[config_file_mode]},
      owner   => ${settings[config_file_owner]},
      group   => ${settings[config_file_group]},
      source  => ${settings[config_file_source]},
      content => ${manage_config_file_content},
      notify  => ${manage_config_file_notify},
      require => ${manage_config_file_require},
    }

    file { ${settings[config_dir_path]}:
      ensure  => ${config_dir_ensure},
      path    => ${settings[config_dir_path]},
      source  => ${config_dir_source},
      recurse => ${settings[config_dir_recurse]},
      purge   => ${settings[config_dir_purge]},
      force   => ${settings[config_dir_force]},
      notify  => ${manage_config_file_notify},
      require => ${manage_config_file_require},
    }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_stdmod_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_stdmod_debug_${title}",
    }
  }

}
