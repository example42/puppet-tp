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

  $packages                  = { } ,
  $services                  = { } ,
  $files                     = { } ,

  $settings_hash             = { } ,

  $auto_repo                 = true,

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  $data_module               = 'tp',

  ) {

  # Parameters validation
  validate_bool($auto_repo)
  validate_hash($packages)
  validate_hash($services)
  validate_hash($files)


  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings=merge($tp_settings,$settings_hash)


  # Dependency class
  if $dependency_class { require $dependency_class }


  # Automatic repo management
  if $auto_repo == true
  and $settings[repo_url] {
    tp::repo { $title:
      before => Package[$settings[package_name]],
    }
  }


  # Resources
  if ! empty($packages) {
    create_resources('package', $packages)
  } else {
    if $settings[package_name] {
      package { $settings[package_name]:
        ensure => $ensure,
      }
    }
  }

  if ! empty($services) {
    create_resources('service', $services)
  } else {
    if $settings[service_name] {
      service { $settings[service_name]:
        ensure => $settings[service_ensure],
        enable => $settings[service_enable],
      }
    }
  }

  if ! empty($files) {
    create_resources('file', $files)
  }


  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
