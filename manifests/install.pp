#
#
# = Define: tp
#
# This class installs and manages tp
#
#
# == Parameters
#
define tp::install (

  $ensure                    = present,

  $conf_hash                 = { } ,
  $dir_hash                  = { } ,

  $settings_hash             = { } ,

  $auto_repo                 = true,

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  $puppi_enable              = false,

  $test_enable               = false,
  $test_acceptance_template  = undef,

  $data_module               = 'tp',

  ) {

  # Parameters validation
  validate_bool($auto_repo)
  validate_bool($puppi_enable)
  validate_hash($conf_hash)
  validate_hash($dir_hash)
  validate_hash($settings_hash)


  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings=merge($tp_settings,$settings_hash)
  $service_require = $settings[package_name] ? {
    ''      => undef,
    undef   => undef,
    default => Package[$settings[package_name]],
  }
  $service_ensure = $ensure ? {
    'present' => $settings[service_ensure],
    true      => $settings[service_ensure],
    'absent'  => 'stopped',
    false     => 'stopped',
  }
  $service_enable = $ensure ? {
    'present' => $settings[service_enable],
    true      => $settings[service_enable],
    'absent'  => false,
    false     => false,
  }

  # Dependency class
  if $dependency_class { require $dependency_class }


  # Automatic repo management
  if $auto_repo == true
  and $settings[repo_url] {
    $repo_enabled = $ensure ? {
      'present' => true,
      true      => true,
      'absent'  => false,
      false     => false,
    }
    tp::repo { $title:
      enabled => $repo_enabled,
      before  => Package[$settings[package_name]],
    }
  }


  # Resources
  if $settings[package_name] {
    package { $settings[package_name]:
      ensure => $ensure,
    }
  }

  if $settings[service_name] {
    service { $settings[service_name]:
      ensure  => $service_ensure,
      enable  => $service_enable,
      require => $service_require,
    }
  }

  if $conf_hash != {} {
    create_resources('tp::conf', $conf_hash )
  }
  if $dir_hash != {} {
    create_resources('tp::dir', $dir_hash )
  }

  if $puppi_enable == true {
    tp::puppi { $title: }
  }

  if $test_enable == true {
    tp::test { $title:
      acceptance_template => $test_acceptance_template,
    }
  }

  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
