# @define tp::install
#
# This define installs the application (app) set in the given title.
# Default installation method is package. Alternative ones are possible
# if the necessary tinydta is present for the app.
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
# @example installation of prometheus directly from a binary of the given version
#   tp::install { 'prometheus':
#     install_method: 'file'
#     ensure: '2.41.0',
#   }
#
# @example installation of a specific version of a package
# Note: the version MUST be a valid for the underlying package provider.
# This setting is not used if there's an array of packages to install
#   tp::install { 'elasticsearch':
#     ensure => '4.0.1',
#   }
#
# @example installation of a package from its upstream repo, rather
#  than default OS based one. Relevant tinydata must be present.
#   tp::install { 'mongodb':
#     upstream_repo => true,
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
#     settings => {
#        package_name     => 'opt_apache',
#        service_enable   => false,
#        config_file_path => '/opt/apache/conf/httpd.conf',
#        config_dir_path  => '/opt/apache/conf/',
#      }
#   }
#
# @example Installation of repo packages via proxy
#   tp::install { 'puppet':
#     repo_exec_environment => [ 'http_proxy=http://proxy.domain:8080','https_proxy=http://proxy.domain:8080'],
#   }
#
# @param ensure Manage application presence.
#   Valid values are present, absent or the package version number.
#
# @param confs An hash of tp::conf resources to create.
#   These resources will refer to the same application specified in the $title.
#
# @param dirs  An hash of tp::dir resources to create.
#   These resources will refer to the same application specified in the $title.
#
# @param options Generic hash of configuration parameters specific for the
#   app, they are passed to tp::test if test_enable parameter is true
#
# @param settings An hash that can override the application settings tp
#   returns, according to the underlying OS and the default behaviour
#
# @param auto_prereq Boolean to enable automatic management of prerequisite dependencies
#   required for the installation of the application. If they are defined in
#   tp data.
#
# @param data_module Name of the module where tp data is looked for
#  Default is tinydata: https://github.com/example42/tinydata
#
define tp::install::package (

  Variant[Boolean,String] $ensure           = present,

  # V4
  Optional[String]        $version          = undef,
  Hash                    $settings         = {},
  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

  Boolean                 $auto_repo        = true,
  Boolean                 $auto_conf        = true,
  Optional[Boolean]       $auto_prerequisites = undef,
  Optional[Boolean]       $auto_prereq      = undef,

  Optional[Boolean]       $upstream_repo    = undef,
  Variant[Undef,String]   $repo             = undef,
  Array                   $repo_exec_environment = [],
  Hash                    $tp_repo_params   = {},
  Boolean                 $manage_package   = true,
  Boolean                 $manage_service   = true,
  Boolean                 $apt_safe_trusted_key = lookup('tp::apt_safe_trusted_key', Boolean , first, false),

  String[1]               $data_module      = 'tinydata',

) {
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $base_package = pick($title_elements[1],'main')
  $sane_app = regsubst($app, '/', '_', 'G')

  $package_provider = pick(getparam("packages.${base_package}.package_provider"),getparam("packages.${app}.package_provider"))

  if $settings[package_provider] == Variant[Undef,String[0]] {
    $real_package_provider = undef
  } else {
    $real_package_provider = $settings[package_provider]
  }

  if $settings[package_source] =~ Variant[Undef,String[0]] {
    $package_source = undef
  } else {
    $package_source = tp::url_replace(getvar('settings.package_source'),tp::get_version($ensure,$version,$settings))
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

  # Automatic repo management
  $use_upstream_repo = pick($upstream_repo,$settings[upstream_repo],false)
  if $auto_repo
  and ( $settings[repo_url]
    or $settings[yum_mirrorlist]
    or $settings[repo_package_url]
  or $settings[repo_file_url]) {
    $repo_enabled = $ensure ? {
      'absent'  => false,
      false     => false,
      default   => true,
    }
    $tp_repo_params_default = {
      enabled              => $repo_enabled,
      before               => Package[$settings[package_name]],
      data_module          => $data_module,
      repo                 => $repo,
      settings_hash        => $settings,
      exec_environment     => $repo_exec_environment,
      upstream_repo        => $use_upstream_repo,
      apt_safe_trusted_key => $apt_safe_trusted_key,
    }
    tp::repo { $app:
      * => $tp_repo_params_default + $tp_repo_params,
    }
  }

  if $auto_prerequisites {
    deprecation('auto_prerequisites','Ignored. Parameter renamed to auto_prereq. s/auto_prerequisites/auto_prereq')
  }

  # Automatic dependencies management, if data defined
  if $auto_prereq and $settings[package_prerequisites] and $ensure != 'absent' {
    case $settings[package_prerequisites] {
      Array: {
        $settings[package_prerequisites].each | $p | {
          if $settings[package_name] {
            Package[$p] -> Package[$settings[package_name]]
          }
          ensure_packages($p)
        }
      }
      Hash: {
        $settings[package_prerequisites].each | $p,$v | {
          if $settings[package_name] {
            Package[$p] -> Package[$settings[package_name]]
          }
          ensure_packages($p, $v)
        }
      }
      String: {
        if $settings[package_name] {
          Package[$settings[package_prerequisites]] -> Package[$settings[package_name]]
        }
        package { $settings[package_prerequisites]: }
        # ensure_packages("${settings[package_prerequisites]}")
      }
      default: {}
    }
  }
  if $auto_prereq and $settings[tp_prerequisites] and $ensure != 'absent' {
    case $settings[tp_prerequisites] {
      Array: {
        $settings[tp_prerequisites].each | $p | {
          if $settings[package_name] {
            Tp::Install[$p] -> Package[$settings[package_name]]
          }
          tp_install($p, { auto_prereq => true })
        }
      }
      Hash: {
        $settings[tp_prerequisites].each | $p,$v | {
          if $settings[package_name] {
            Tp::Install[$p] -> Package[$settings[package_name]]
          }
          $tp_install_params = { auto_prereq => true } + $v
          tp_install($p, $tp_install_params)
        }
      }
      String: {
        if $settings[package_name] {
          Tp::Install[$settings[tp_prerequisites]] -> Package[$settings[package_name]]
        }
        tp_install($settings[tp_prerequisites], { auto_prereq => true })
      }
      default: {}
    }
  }
  if $auto_prereq and $settings['exec_prerequisites'] and $ensure != 'absent' {
    $settings[exec_prerequisites].each | $k , $v | {
      if $settings[package_name] {
        Exec[$k] -> Package[$settings[package_name]]
      }
      exec { $k:
        * => { 'path' => $facts['path'] } + $v,
      }
    }
  }
  if $auto_prereq and $settings['extra_prerequisites'] and $ensure != 'absent' {
    $settings['extra_prerequisites'].each | $k,$v | {
      create_resources($k,$v, { before => Package[$settings[package_name]] })
    }
  }
  if $auto_prereq and $settings['exec_postinstall'] and $ensure != 'absent' {
    $settings[exec_postinstall].each | $k , $v | {
      if $settings[package_name] {
        Package[$settings[package_name]] -> Exec[$k]
      }
      exec { $k:
        * => { 'path' => '/bin:/usr/bin:/sbin:/usr/sbin' } + $v,
      }
    }
  }
  if $auto_prereq and $settings['extra_postinstall'] and $ensure != 'absent' {
    $settings['extra_postinstall'].each | $k,$v | {
      create_resources($k,$v, { require => Package[$settings[package_name]] })
    }
  }

  # Resources
  $packages = pick($settings['package_name'])

  if $manage_package {
    case $packages {
      Hash: {
        $package_defaults = {
          ensure   => $plain_ensure,
          provider => $real_package_provider,
        }
        $packages.each |$kk,$vv| {
          package { $kk:
            * => $package_defaults + pick($settings[package_params], {} + $vv),
          }
        }
      }
      Array: {
        $package_defaults = {
          ensure   => $plain_ensure,
          provider => $real_package_provider,
        }
        $packages.each |$k| {
          package { $k:
            * => $package_defaults + pick($settings[package_params], {}),
          }
        }
      }
      String[1]: {
        $package_defaults = {
          ensure          => pick($version,$ensure),
          provider        => $real_package_provider,
          source          => $package_source,
          install_options => $package_install_options,
        }
        package { $packages:
          * => $package_defaults + pick($settings[package_params], {}),
        }
      }
      Undef: {
        # do nothing
      }
      default: {
        tp::fail($on_missing_data, "tp::install::package ${app} - No data for ${packages}. Valid types are String, Array, Hash, Undef.")
      }
    }
  }

  $services = pick_default($settings['service_name'],undef)
  if $manage_service {
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
    $service_require = $packages ? {
      Hash      => Package[$packages.keys],
      Array     => Package[$packages],
      String[1] => Package[$packages],
      default   => undef,
    }
    case $services {
      Hash: {
        $service_defaults = {
          ensure  => $service_ensure,
          enable  => $service_enable,
          require => $service_require,
        }
        $services.each |$kk,$vv| {
          service { $kk:
            * => $service_defaults + pick($settings[service_params], {} + $vv),
          }
        }
      }
      Array: {
        $service_defaults = {
          ensure  => $service_ensure,
          enable  => $service_enable,
          require => $service_require,
        }
        $services.each |$k| {
          service { $k:
            * => $service_defaults + pick($settings[service_params], {}),
          }
        }
      }
      String[1]: {
        $service_defaults = {
          ensure  => $service_ensure,
          enable  => $service_enable,
          require => $service_require,
        }
        service { $services:
          * => $service_defaults + pick($settings[service_params], {}),
        }
      }
      Undef: {
        # do nothing
      }
      '': {
        # do nothing
      }
      default: {
        tp::fail($on_missing_data,"tp::install::package ${app} - Unsupported type for ${services}. Valid types are String, Array, Hash, Undef.") # lint-ignore:140chars
      }
    }
  }
}
