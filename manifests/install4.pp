# @define tp::install4
#
# This define is equivalent to tp::install but is compatible
# only with Puppet 4 or Puppet > 3.7 with future parser enabled
#
# Check documentation of tp::install for usage and reference.
#
define tp::install4 (

  String[1]             $ensure           = present,

  Hash                  $conf_hash        = { },
  Hash                  $dir_hash         = { },

  Hash                  $settings_hash    = { },

  Boolean               $auto_repo        = true,

  Variant[Undef,String] $dependency_class = undef,
  Variant[Undef,String] $monitor_class    = undef,
  Variant[Undef,String] $firewall_class   = undef,

  Boolean               $puppi_enable     = false,

  Boolean               $test_enable      = false,
  Variant[Undef,String] $test_template    = undef,

  String[1]             $data_module      = 'tp',

  ) {

  # Settings evaluation
  $tp_settings = tp_lookup($title,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash
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
  if $dependency_class and $dependency_class != '' {
    require $dependency_class
  }

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
    $packages_array=any2array($settings[package_name])
    $packages_array.each |$pkg| {
      package { $pkg:
        ensure => $ensure,
      }
    }
  }

  if $settings[service_name] {
    $services_array=any2array($settings[service_name])
    $services_array.each |$svc| {
      service { $svc:
        ensure  => $service_ensure,
        enable  => $service_enable,
        require => $service_require,
      }
    }
  }

  if $conf_hash != {} {
    create_resources('tp::conf', $conf_hash )
  }
  if $dir_hash != {} {
    create_resources('tp::dir', $dir_hash )
  }


  # Optional puppi integration 
  if $puppi_enable == true {
    tp::puppi { $title:
      settings_hash => $settings,
    }
  }

  # Test script creation (use to test, check, monitor the app)
  if $test_enable == true {
    tp::test { $title:
      settings_hash       => $settings,
      acceptance_template => $test_template,
    }
  }

  # Extra classes
  if $monitor_class and $monitor_class != '' {
    include $monitor_class
  }
  if $firewall_class and $firewall_class != '' {
    include $firewall_class
  }

}
