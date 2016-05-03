# @define tp::install3
#
# Note: This is a Puppet 3.x compatible version of tp::install
#
# This define installs the application (app) set in the given title.
# It manages the packages presence and, eventually, the relevant
# services on the supported Operating Systems.
# Several parameters allow any kind of override of default settings and
# customization.
# The list of supported applications, and the relevant OS coverage is in
# the data/ directory of the referred data_module.
#
# @example installation (of any any supported app and OS):
#   tp::install3 { $app: }
#
# @example installation of postfix
#   tp::install3 { 'postfix': }
#
# @example installation and configuration via an options_hash
# Note: this works when auto_conf is true (as default) AND when
# is defined $settings['config_file_template'] with a valid template
# in the used data module (default: tinydata)
#   tp::install { 'puppetserver':
#     options_hash => hiera('puppetserver::options'),
#   }
#
# @example installation and configuration via a custom hash of tp::conf3
# resources used to manage configuration files
# Here eventual auto configuration is explicitly disabled
#   tp::install3 { 'puppet':
#     conf_hash => hiera('tp::puppet::confs'),
#     auto_conf => false,
#   }
#
# @example installation with custom settings
#   tp::install3 { 'apache':
#     settings_hash => {
#        package_name     => 'opt_apache',
#        service_enable   => false,
#        config_file_path => '/opt/apache/conf/httpd.conf',
#        config_dir_path  => '/opt/apache/conf/',
#      }
#   }
#
# @param ensure                    Default: present
#   Manage application status. Valid values are present, absent or the
#   package version number.
#
# @param conf_hash                 Default: { }
#   An hash of tp::conf3 resources that feed a create_resources function call.
#
# @param dir_hash                  Default: { }
#   An hash of tp::dir3 resources that feed a create_resources function call.
#
# @param options_hash              Default: { },
#   Generic hash of configuration parameters specific for the app
#
# @param settings_hash             Default: { }
#   An hash that can override the application settings tp returns, according
#   to the underlying Operating System and the default behaviour
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
#   If true, it is called the define tp::test3, which creates a script that
#   should test the functionality of the app
#
# @param test_template  Default: undef
#   Custom template to use to for the content of test script, used
#   by the tp::test3 define. It requires test_enable = true
#
# @param debug                     Default: false,
#   If set to true it prints debug information for tp into the directory set in
#   debug_dir
#
# @param debug_dir                 Default: '/tmp',
#   The directory where tp stores dbug info, when enabled
#
# @param data_module               Default: 'tinydata'
#   Name of the module where tp data is looked for
#
define tp::install3 (

  $ensure                    = present,

  $conf_hash                 = { } ,
  $dir_hash                  = { } ,

  $options_hash              = { } ,
  $settings_hash             = { } ,

  $auto_repo                 = true,
  $auto_conf                 = true,

  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  $puppi_enable              = false,

  $test_enable               = false,
  $test_template             = undef,

  $debug                     = false,
  $debug_dir                 = '/tmp',

  $data_module               = 'tinydata',

  ) {

  # Parameters validation
  validate_bool($auto_repo)
  validate_bool($auto_conf)
  validate_bool($puppi_enable)
  validate_bool($debug)
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
    'absent' => 'stopped',
    false    => 'stopped',
    default  => $settings[service_ensure],
  }
  $service_enable = $ensure ? {
    'absent' => false,
    false    => false,
    default  => $settings[service_enable],
  }

  # Dependency class
  if $dependency_class and $dependency_class != '' {
    include $dependency_class
  }


  # Automatic repo management
  if $auto_repo == true
  and $settings[repo_url]
  or $settings[yum_mirrorlist] {
    $repo_enabled = $ensure ? {
      'absent'  => false,
      false     => false,
      default   => true,
    }
    tp::repo3 { $title:
      enabled => $repo_enabled,
      before  => Package[$settings[package_name]],
    }
  }


  # Resources
  if $settings[package_name] {
    ensure_resource( 'package', $settings[package_name], {
      'ensure' => $ensure,
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
    create_resources('tp::conf3', $conf_hash )
  }
  if $dir_hash != {} {
    create_resources('tp::dir3', $dir_hash )
  }


  # Optional puppi integration
  if $puppi_enable == true {
    tp::puppi3 { $title:
      settings_hash => $settings,
    }
  }

  # Test script creation (use to test, check, monitor the app)
  if $test_enable == true {
    tp::test3 { $title:
      settings_hash => $settings,
      options_hash  => $options_hash,
      template      => $test_template,
    }
  }

  if $auto_conf and $settings['config_file_template'] {
    ::tp::conf3 { $title:
      template     => $settings['config_file_template'],
      options_hash => $options_hash,
    }
  }
  if $auto_conf and $settings['init_file_template'] {
    ::tp::conf3 { "${title}::init":
      template     => $settings['init_file_template'],
      options_hash => $options_hash,
      base_file    => 'init',
    }
  }

  # Extra classes
  if $monitor_class and $monitor_class != '' {
    include $monitor_class
  }
  if $firewall_class and $firewall_class != '' {
    include $firewall_class
  }

  # Debugging
  if $debug == true {
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "SCOPE:\n${debug_scope}"

    file { "tp_install_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_install_debug_${title}",
    }
  }


}
