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
#     options_hash => lookup('puppetserver::options', {merge => deep}),
#   }
#
# @example installation and configuration via a custom hash of tp::conf
# resources used to manage configuration files.
# Here eventual auto configuration is explicitly disabled
#
#   tp::install { 'puppet':
#     conf_hash => lookup('puppet::tp_confs', {merge => deep}),,
#     auto_conf => false,
#   }
#
# @example installation with custom settings
#   tp::install { 'apache':
#     settings_hash       => {
#        package_name     => 'opt_apache',
#        service_enable   => false,
#        config_file_path => '/opt/apache/conf/httpd.conf',
#        config_dir_path  => '/opt/apache/conf/',
#      }
#   }
#
# @param ensure Manage application status.
#   Valid values are present, absent or the package version number.
#
# @param conf_hash An hash of tp::conf resources to create.
#   These resources will refer to the same application specified in the $title.
#
# @param dir_hash  An hash of tp::dir resources to create.
#   These resources will refer to the same application specified in the $title.
#
# @param options_hash Generic hash of configuration parameters specific for the
#   app, they are passed to tp::test if test_enable parameter is true
#
# @param settings_hash An hash that can override the application settings tp
#   returns, according to the underlying OS and the default behaviour
#
# @param auto_repo Boolean to enable automatic package repo management for the
#   specified application. Repo data is not always provided.
#
# @param auto_prereq Boolean to enable automatic management of prerequisite dependencies
#   required for the installation of the application. If they are defined in
#   tp data.
#
# @param repo Name of the repository to use. Multiple different repositories may
#   be used, if they are defined in Tiny Puppet data.
#
# @param auto_conf Boolean to enable automatic configuration of the application.
#   If true and there's a valid value for $settings['config_file_template']
#   then the relevant template is added via tp::conf based on the default
#   $options (they can be overriden by the options_hash parameter).
#
# @param cli_enable Enable cli integration.
#   If true, tp commands to query apps installed via tp are added to the system.
#
# @param puppi_enable Enable puppi integration. Default disabled.
#   If set true, the puppi module is needed.
#
# @param test_enable If true, it is called the define tp::test, which allows
#   to test the status of the application from the command line.
#
# @param test_template Custom template to use to for the content of test script,
#   used by the tp::test define. It requires test_enable = true
#
# @param debug If set to true it prints debug information for tp into the
#   directory set in debug_dir
#
# @param debug_dir The directory where tp stores debug info, if enabled.
#
# @param data_module Name of the module where tp data is looked for
#  Default is tinydata: https://github.com/example42/tinydata
#
define tp::install (

  Variant[Boolean,String] $ensure           = present,

  Hash                    $conf_hash        = { },
  Hash                    $dir_hash         = { },

  Hash                    $options_hash     = { },
  Hash                    $settings_hash    = { },

  Boolean                 $auto_repo        = true,
  Boolean                 $auto_conf        = true,
  Optional[Boolean]       $auto_prerequisites = undef,
  Boolean                 $auto_prereq      = false,

  Variant[Undef,String]   $repo             = undef,

  Boolean                 $manage_package   = true,
  Boolean                 $manage_service   = true,

  Boolean                 $cli_enable       = false,
  Boolean                 $puppi_enable     = false,
  Boolean                 $test_enable      = false,
  Variant[Undef,String]   $test_template    = undef,

  Boolean                 $debug            = false,
  String[1]               $debug_dir           = '/tmp',

  String[1]               $data_module      = 'tinydata',

  ) {

  $app = $title
  # Settings evaluation
  $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  if $settings[package_name] == Variant[Undef,String[0]]
  or $manage_package == false {
    $service_require = undef
  } else {
    $service_require = Package[$settings[package_name]]
  }

  if $settings[package_provider] == Variant[Undef,String[0]] {
    $package_provider = undef
  } else {
    $package_provider = $settings[package_provider]
  }

  if $settings[package_source] == Variant[Undef,String[0]] {
    $package_source = undef
  } else {
    $package_source = $settings[package_source]
  }

  if $settings[package_install_options] == Variant[Undef,String[0]] {
    $package_install_options = undef
  } else {
    $package_install_options = $settings[package_install_options]
  }

  $plain_ensure = $ensure ? {
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
  and ( $settings[repo_url] or $settings[yum_mirrorlist] or $settings[repo_package_url] ) {
    $repo_enabled = $ensure ? {
      'absent'  => false,
      false     => false,
      default   => true,
    }
    tp::repo { $app:
      enabled       => $repo_enabled,
      before        => Package[$settings[package_name]],
      data_module   => $data_module,
      repo          => $repo,
      settings_hash => $settings_hash,
    }
  }

  if $auto_prerequisites {
    deprecation('auto_prerequisites','Ignored. Parameter renamed to auto_prereq. s/auto_prerequisites/auto_prereq')
  }

  # Automatic dependencies management, if data defined
  if $auto_prereq and $settings[package_prerequisites] {
    $settings[package_prerequisites].each | $p | {
      Package[$p] -> Package[$settings[package_name]]
      ensure_packages($p)
    }
  }
  if $auto_prereq and $settings[tp_prerequisites] {
    $settings[tp_prerequisites].each | $p | {
      Tp::Install[$p] -> Package[$settings[package_name]]
      tp_install($p, { auto_prereq => true })
    }
  }
  if $auto_prereq and $settings[exec_prerequisites] {
    $settings[exec_prerequisites].each | $k , $v | {
      Exec[$k] -> Package[$settings[package_name]]
      exec { $k:
        * => { 'path' => '/bin:/usr/bin:/sbin:/usr/sbin' } + $v,
      }
    }
  }
  if $auto_prereq and $settings[exec_postinstall] {
    $settings[exec_postinstall].each | $k , $v | {
      Package[$settings[package_name]] -> Exec[$k]
      exec { $k:
        * => { 'path' => '/bin:/usr/bin:/sbin:/usr/sbin' } + $v,
      }
    }
  }


  # Resources
  if $settings[package_name] =~ Array and $manage_package {
    $settings[package_name].each |$pkg| {
      package { $pkg:
        ensure   => $plain_ensure,
        provider => $package_provider,
      }
    }
  }
  if $settings[package_name] =~ String[1] and $manage_package {
    package { $settings[package_name]:
      ensure          => $ensure,
      provider        => $package_provider,
      source          => $package_source,
      install_options => $package_install_options,
    }
  }

  if $settings[service_name] and $manage_service {
    $services_array=any2array($settings[service_name])
    $services_array.each |$svc| {
      service { $svc:
        ensure  => $service_ensure,
        enable  => $service_enable,
        require => $service_require,
      }
    }
  }

  # Manage additional tp::conf as in conf_hash
  $conf_defaults = {
    'ensure'        => $ensure,
    'settings_hash' => $settings,
    'options_hash'  => $options_hash,
  }
  if $conf_hash != {} {
    $conf_hash.each |$k,$v| {
      tp::conf { $k:
        * => $conf_defaults + $v,
      }
    }
  }

  # Manage additional tp::dir as in dir_hash
  $dir_defaults = {
    'ensure'        => $ensure,
    'settings_hash' => $settings,
  }
  if $dir_hash != {} {
    $dir_hash.each |$k,$v| {
      tp::dir { $k:
        * => $dir_defaults + $v,
      }
    }
  }

  # Auto manage config files if present
  if $auto_conf and $settings['config_file_template'] {
    ::tp::conf { $app:
      template     => $settings['config_file_template'],
      options_hash => $options_hash,
      data_module  => $data_module,
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
  if $test_enable and $test_template {
    tp::test { $app:
      settings_hash => $settings,
      options_hash  => $options_hash,
      template      => $test_template,
      data_module   => $data_module,
    }
  }

  # Optional puppi integration
  if $puppi_enable {
    tp::puppi { $app:
      settings_hash => $settings,
      data_module   => $data_module,
    }
  }

  # Options cli integration
  if $cli_enable {
    file { "/etc/tp/app/${app}":
      ensure  => $plain_ensure,
      content => inline_template('<%= @settings.to_yaml %>'),
    }
    include ::tp
  }

  # Debugging
  if $debug == true {
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    file { "tp_install_debug_${title}":
      ensure  => present,
      content => $debug_scope,
      path    => "${debug_dir}/tp_install_debug_${title}",
    }
  }
}
