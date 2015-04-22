# @define tp::install
#
# This define installs the application (app) set in the given title.
# It manages the packages presence and, eventually, the relevant
# services on the supported Operating Systems.
# Several parameters allow any kind of override of default settings and
# customization.
# The list of supported applications, and the relevant OS coverage is in
# the data/ directory of this module.
#
# @example installation (of any any supported app and OS):
#   tp::install { $app: }
#
# @example installation of postfix
#   tp::install { 'postfix': }
#
# @example disinstallation of nginx
#   tp::install { 'nginx':
#     ensure => absent,
#   }
#
# @example installation and configuration via a custom hash of tp::conf
# resources used to manage configuration files
#   tp::install { 'puppet':
#     conf_hash => hiera('tp::puppet::confs'),
#   }
#
# @example installation with custom settings
#   tp::install { 'apache':
#     settings_hash => {
#        package_name     => 'opt_apache',
#        service_enable   => false,
#        config_file_path => '/opt/apache/conf/httpd.conf',
#        config_dir_path  => '/opt/apache/conf/',
#      }
#   }
#
# @param ensure                    Default: present
#   Define if to install (present, default value) or remove (absent) the application.
#
# @param conf_hash                 Default: { } 
#   An hash of tp::conf resources that feed a create_resources function call.
#
# @param dir_hash                  Default: { } 
#   An hash of tp::dir resources that feed a create_resources function call.
#
# @param settings_hash             Default: { } 
#   An hash that can override the application settings tp returns, according to the
#   underlying Operating System and the default behaviour
#
# @param auto_repo                 Default: true
#   Boolean to enable automatic package repo management for the specified
#   application. Repo data is not always provided.
#
# @param dependency_class          Default: undef
#   Optional name of a custom class whe you can manage depenencies
#   required for the installation of the given application
#
# @param monitor_class             Default: undef
#   Optional name of a custom class where you can manage the
#   monitoring of this application.
#
# @param firewall_class            Default: undef
#   Optional name of a custom class where you can manage the
#   monitoring of this application.
#
# @param puppi_enable              Default: false
#   Enable puppi integration. Default disabled.
#   If set true, the puppi module is needed.
#   
# @param test_enable               Default: false
#   If true, it is called the define tp::test, which creates a script that
#   should test the functionality of the app
#
# @param test_template  Default: undef
#   Custom template to use to for the content of test script, used 
#   by the tp::test define. It requires test_enable = true
#
# @param data_module               Default: 'tp'
#   Name of the module where tp data is looked for
#
define tp::install (

  $ensure                    = present,

  $conf_hash                 = { } ,
  $dir_hash                  = { } ,

  $settings_hash             = { } ,

  $auto_repo                 = true,

  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  $puppi_enable              = false,

  $test_enable               = false,
  $test_template             = undef,

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
    ensure_resource( 'package', $settings[package_name], {
      'ensure' => $ensure
    } )
  }

  if $settings[service_name] {
    ensure_resource( 'service', $settings[service_name], {
      'ensure'  => $service_ensure,
      'enable'  => $service_enable,
      'require' => $service_require,
    } )
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
      settings_hash => $settings,
      template      => $test_acceptance_template,
    }
  }

  # Extra classes
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
