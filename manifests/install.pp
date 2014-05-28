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

  $packages  = { } ,
  $services  = { } ,
  $files     = { } ,

  $settings  = { } ,

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  ) {

  $tp_packages=tp_lookup($title,'packages')
  $tp_services=tp_lookup($title,'services')
  $tp_files=tp_lookup($title,'files')

  $real_packages=merge($tp_packages,$packages)
  $real_services=merge($tp_services,$services)
  $real_files=merge($tp_files,$files)


  # Dependency class
  if $dependency_class { include $dependency_class }


  # Resources
  if $real_packages {
    create_resources('package', $real_packages)
  }

  if $real_services {
    create_resources('service', $real_services)
  }

  if $real_files {
    create_resources('file', $real_files)
  }


  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
