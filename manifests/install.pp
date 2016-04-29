# @define tp::install
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
#   tp::install { $app: }
#
# @example installation of postfix
#   tp::install { 'postfix': }
#
# @example installation of a specific version of a package
# Note: the version MUST be a valid for the underlying package provider.
# This setting is not used if there's an array of packages to install
#   tp::install { 'elasticsearch':
#     ensure => '4.0.1',
#   }
#
# @example installation and configuration via an options_hash
# Note: this works when auto_conf is true (as default) AND when
# is defined $settings['config_file_template'] with a valid template
# in the used data module (default: tinydata)
#   tp::install { 'puppetserver':
#     options_hash => hiera('puppetserver::options'),
#   }
#
# @example installation and configuration via a custom hash of tp::conf
# resources used to manage configuration files.
# Here eventual auto configuration is explicitly disabled
#
#   tp::install { 'puppet':
#     conf_hash => hiera('tp::puppet::confs'),
#     auto_conf => false,
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
#   Manage application status. Valid values are present, absent or the
#   package version number.
#
# @param conf_hash                 Default: { }
#   An hash of tp::conf resources that feed a create_resources function call.
#
# @param dir_hash                  Default: { }
#   An hash of tp::dir resources that feed a create_resources function call.
#
# @param options_hash              Default: { },
#   Generic hash of configuration parameters specific for the app, they are
#   passed to tp::test if test_enable parameter is true
#
# @param settings_hash             Default: { }
#   An hash that can override the application settings tp returns, according to the
#   underlying Operating System and the default behaviour
#
# @param auto_repo                 Default: true
#   Boolean to enable automatic package repo management for the specified
#   application. Repo data is not always provided.
#
# @param auto_conf                 Default: true
#   Boolean to enable automatic configuration of the application.
#   If true and there's a valid value for $settings['config_file_template']
#   then the relevant template is added via tp::conf based on the default
#   $options (they can be overriden by the options_hash parameter).
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
# @param debug                     Default: false,
#   If set to true it prints debug information for tp into the directory set in
#   debug_dir
#
# @param debug_dir                 Default: '/tmp',
#   The directory where tp stoes dbug info, when enabled
#
# @param data_module               Default: 'tinydata'
#   Name of the module where tp data is looked for
#
#
define tp::install (

  Variant[Boolean,String] $ensure           = present,

  Hash                    $conf_hash        = { },
  Hash                    $dir_hash         = { },

  Hash                    $options_hash     = { },
  Hash                    $settings_hash    = { },

  Boolean                 $auto_repo        = true,
  Boolean                 $auto_conf        = true,

  Boolean                 $puppi_enable     = false,

  Boolean                 $test_enable      = false,
  Variant[Undef,String]   $test_template    = undef,

  Boolean                 $debug            = false,
  String[1]               $debug_dir        = '/tmp',

  String[1]               $data_module      = 'tinydata',

  ) {

  $app = $title
  # Settings evaluation
  $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  if $settings[package_name] == Variant[Undef,String[0]] {
    $service_require = undef
  } else {
    $service_require = Package[$settings[package_name]]
  }

  if $settings[package_provider] == Variant[Undef,String[0]] {
    $package_provider = undef
  } else {
    $package_provider = $settings[package_provider]
  }

  $packages_ensure = $ensure ? {
    'absent' => 'absent',
    false    => 'absent',
    default  => 'present',
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

  # Automatic repo management
  if $auto_repo == true
  and $settings[repo_url]
  or $settings[yum_mirrorlist] {
    $repo_enabled = $ensure ? {
      'absent'  => false,
      false     => false,
      default   => true,
    }
    tp::repo { $app:
      enabled => $repo_enabled,
      before  => Package[$settings[package_name]],
    }
  }


  # Resources
  if $settings[package_name] =~ Array {
    $settings[package_name].each |$pkg| {
      package { $pkg:
        ensure   => $packages_ensure,
        provider => $package_provider,
      }
    }
  }
  if $settings[package_name] =~ String[1] {
    package { $settings[package_name]:
      ensure   => $ensure,
      provider => $package_provider,
      # tag      => $app,
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

  $resources_defaults = {
    'settings_hash' => $settings,
    'options_hash'  => $options_hash,
  }
  if $conf_hash != {} {
    create_resources('tp::conf', $conf_hash, $resources_defaults )
  }
  if $dir_hash != {} {
    create_resources('tp::dir', $dir_hash, $resources_defaults )
  }

  if $auto_conf and $settings['config_file_template'] {
    ::tp::conf { $app:
      template     => $settings['config_file_template'],
      options_hash => $options_hash,
    }
  }
  if $auto_conf and $settings['init_file_template'] {
    ::tp::conf { "${app}::init":
      template     => $settings['init_file_template'],
      options_hash => $options_hash,
      base_file    => 'init',
    }
  }

  # Optional test automation integration
  if $test_enable == true {
    tp::test { $app:
      settings_hash => $settings,
      options_hash  => $options_hash,
      template      => $test_template,
    }
  }

  # Optional puppi integration
  if $puppi_enable == true {
    tp::puppi { $app:
      settings_hash => $settings,
    }
  }

}
