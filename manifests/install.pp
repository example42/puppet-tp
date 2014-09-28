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

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  ) {

  $tp_settings=tp_lookup($title,'settings','merge')
  # $settings=$tp_settings
  $settings=merge($tp_settings,$settings_hash)


  # Dependency class
  if $dependency_class { require $dependency_class }


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
