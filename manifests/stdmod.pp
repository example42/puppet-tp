#
# = Define: tp::stdmod
#
# This defines reproduces a standard module based
# on a this stdmod standard template
# (https://github.com/stdmod/puppet-skeleton-standard)
#
# The define exposes stdmod compiant parameters for
# standard package, service, configuration setups.
#
define tp::stdmod (

  $package_name              = undef,
  $package_ensure            = undef,

  $service_name              = undef,
  $service_ensure            = undef,
  $service_enable            = undef,

  $config_file_path          = undef,
  $config_file_replace       = undef,
  $config_file_require       = undef,
  $config_file_notify        = undef,
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

  ) {

  # TODO: Find the right way to merge parameters and default settings
  $tp_settings = tp_lookup($title,'settings','merge')
  # $params_settings = inline_template('<%= scope.to_hash %>')
  $params_settings = {}
  $real_settings = merge($params_settings,$tp_settings)


  # Internal variables
  $manage_config_file_content = tp_content($config_file_content, $config_file_template, $config_file_epp)

  $manage_config_file_notify  = $config_file_notify ? {
    'default' => "Service[$title]",
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

  if $real_settings[package_name] {
    package { $real_settings[package_name]:
      ensure => $ensure,
    }
  }

  if $real_settings[service_name] {
    service { $real_settings[service_name]:
      ensure => $real_settings[service_ensure],
      enable => $real_settings[service_enable],
    }
  }

  if $real_settings[config_file_source]
  or $manage_config_file_content
  or $config_file_ensure == 'absent' {
    file { $real_settings[config_file_path]:
      ensure  => $config_file_ensure,
      path    => $real_settings[config_file_path],
      mode    => $real_settings[config_file_mode],
      owner   => $real_settings[config_file_owner],
      group   => $real_settings[config_file_group],
      source  => $real_settings[config_file_source],
      content => $manage_config_file_content,
      notify  => $manage_config_file_notify,
      require => $real_settings[config_file_require],
    }
  }

  if $config_dir_source {
    file { $real_settings[config_dir_path]:
      ensure  => $config_dir_ensure,
      path    => $real_settings[config_dir_path],
      source  => $config_dir_source,
      recurse => $real_settings[config_dir_recurse],
      purge   => $real_settings[config_dir_purge],
      force   => $real_settings[config_dir_force],
      notify  => $real_settings[manage_config_file_notify],
      require => $real_settings[config_file_require],
    }
  }


  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
