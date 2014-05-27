#
# = Define: tp::install
#
# This defines installs and managed a tp supported application
# It requires Puppet version > 4 or future parser enabled on Puppet > 3.4
#
# == Parameters
#
define tp::installng (

  $packages  = { } ,
  $services  = { } ,
  $files     = { } ,

  $settings    = { } ,

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  ) {

  $real_packages=tp_lookup($title,'packages')
  $real_services=tp_lookup($title,'services')
  $real_files=tp_lookup($title,'files')

  # Dependency class
  if $dependency_class { include $dependency_class }

  # Resources
  if $real_packages {
    $real_settings.each |$pkg| {
      package { $pkg:
        ensure => $ensure,
      }
    }
  }

  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
