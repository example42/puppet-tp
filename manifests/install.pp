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
#     settings_hash       => {
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
# @param upstream_repo Boolean to enable usage of upstream repo for the app and
#   install packages from it rather than default local OS one
#   For working needs relevant tinydata settings, like repo_package_url or
#   repo_url. If auto_repo is false, no repo is managed at all, even if
#   upstream_repo is true.
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
# @repo_exec_environment Array to use for the environment argument of exec types
#   used inside tp::repo define. Used if $auto_repo is true. Can be useful when trying
#   to use tp::repo from behing  a proxy
#
# @param tp_repo_params An hash of additional parameters to pass to the tp::repo define,
#   in case it is used. These params are merged with the ones coming from other
#   repo related parameters and are supposed to be used for special cases.
#
# @param apt_safe_trusted_key Boolean to enable the use of safe management of apt keys
#   (Stop using apt-key add)
#
# @param auto_conf Boolean to enable automatic configuration of the application.
#   If true and there's are valid values for tinydata $settings['config_file_template']
#   and $settings['init_file_template'] then the relevant
#   file is managed according to tinydata defaults and user's $options_hash.
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

  # Temporary flag to use v4 code
  Boolean                 $use_v4           = pick(getvar('tp::use_v4'),false),

  # V4 params
  Optional[Enum['package', 'image', 'file', 'source']] $install_method = undef,
  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

  String $base_package   = 'main',

  Hash $confs            = {},
  Hash $dirs             = {},

  Hash $options          = {},

  Hash $my_settings      = {},

  Hash $tp_params                           = {},
  Hash $params                              = {},

  Optional[String] $version                 = undef,
  Optional[String] $source                  = undef,
  Optional[String] $destination             = undef,

# Legacy params preserved
#  Boolean                 $auto_prereq      = false,
#  Boolean                 $cli_enable       = false,
#  String[1]               $data_module      = 'tinydata',

  # Legacy params deprecated
  Hash                    $conf_hash        = {},
  Hash                    $dir_hash         = {},

  Hash                    $options_hash     = {},
  Hash                    $settings_hash    = {},

  Boolean                 $auto_repo        = true,
  Boolean                 $auto_conf        = true,
  Optional[Boolean]       $auto_prerequisites = undef,
  Boolean                 $auto_prereq      = pick(getvar('tp::auto_prereq'), false),

  Optional[Boolean]       $upstream_repo    = undef,
  Variant[Undef,String]   $repo             = undef,
  Array                   $repo_exec_environment = [],
  Hash                    $tp_repo_params   = {},
  Boolean                 $manage_package   = true,
  Boolean                 $manage_service   = true,
  Boolean                 $apt_safe_trusted_key = lookup('tp::apt_safe_trusted_key', Boolean , first, false),

  Boolean                 $cli_enable       = pick(getvar('tp::cli_enable'), false),
  Boolean                 $puppi_enable     = false,
  Boolean                 $test_enable      = false,
  Variant[Undef,String]   $test_template    = undef,

  Boolean                 $debug            = false,
  String[1]               $debug_dir        = '/tmp',

  String[1]               $data_module      = 'tinydata',

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  if $conf_hash != {} {
    deprecation('conf_hash', 'Replace with confs')
  }
  if $dir_hash != {} {
    deprecation('dir_hash', 'Replace with dirs')
  }
  if $options_hash != {} {
    deprecation('options_hash', 'Replace with options')
  }
  if $settings_hash != {} {
    deprecation('settings_hash', 'Replace with my_settings')
  }

  # Settings evaluation
  $tinydata_settings = tp_lookup($app,'settings',$data_module,'deep_merge')
  $local_settings = delete_undef_values({
      install_method => $install_method,
      repo           => $repo,
      upstream_repo  => $upstream_repo,
      git_source     => $install_method ? {
        'source' => $source,
        default  => undef,
      },
      destination    => pick($install_method, getvar('tinydata_settings.install_method')) ? {
        'source' => pick($destination, "${tp::real_tp_params['data']['path']}/source/${app}"),
        'file'   => pick($destination, "${tp::real_tp_params['data']['path']}/download/${app}"),
        default  => undef,
      },
  })

  $settings = deep_merge($tinydata_settings,$settings_hash,$my_settings,$local_settings)

  # v4 code
  if $use_v4 {
    include tp
    $real_tp_params = $tp::real_tp_params
    $default_install_params = {
      ensure          => $ensure,
      auto_prereq     => $auto_prereq,
      settings        => $settings,
      version         => $version,
      on_missing_data => $on_missing_data,
    }

    # If not user specified or set as settings.install_method, the default
    # installation method is 'package'
    $real_install_method = pick($install_method, getvar('settings.install_method'), 'package')

    case $real_install_method {
      'package': {
        $default_install_package_params = {
          data_module           => $data_module,
          base_package          => $base_package,
          upstream_repo         => $upstream_repo,
          auto_repo             => $auto_repo,
          repo                  => $repo,
          repo_exec_environment => $repo_exec_environment,
          tp_repo_params        => $tp_repo_params,
          apt_safe_trusted_key  => $apt_safe_trusted_key,
          manage_package        => $manage_package,
          manage_service        => $manage_service,
        }
        tp::install::package { $app:
          * => $default_install_params + $default_install_package_params + $params,
        }
      }
      'source': {
        tp::install::source { $app:
          * => $default_install_params + $params,
        }
      }
      'file': {
        $default_install_file_params = {
          source      => $source,
          destination => $destination,
        }
        tp::install::file { $app:
          * => $default_install_params + $default_install_file_params + $params,
        }
      }
      'image': {
        tp::install::image { $app:
          * => $default_install_params + $params,
        }
      }
      default: {
        fail("Invalid install_method ${real_install_method}")
      }
    }

    # Cli integration
    if $cli_enable {
      include tp::cli
      $tp_dir = $tp::tp_dir
      file { "${tp_dir}/app/${sane_app}":
        ensure  => tp::ensure2file($ensure),
        content => inline_epp('<%= $settings.to_yaml %>'),
      }
      file { "${tp_dir}/shellvars/${sane_app}":
        ensure  => tp::ensure2file($ensure),
        content => epp('tp/shellvars.epp', { settings => $settings , }),
      }
    }

    # Additional confs and dirs
    $conf_defaults = {
      'ensure'        => tp::ensure2file($ensure),
      'settings_hash' => $settings,
      'options_hash'  => $options_hash + $options,
      'data_module'   => $data_module,
    }
    $confs.each |$k,$v| {
      tp::conf { $k:
        * => $conf_defaults + $v,
      }
    }

    if $options_hash != {} and getvar('settings.files.config.format') {
      tp::conf { $app:
        * => $conf_defaults,
      }
    }
    $dir_defaults = {
      'ensure'        => tp::ensure2dir($ensure),
      'settings_hash' => $settings,
      'data_module'   => $data_module,
    }
    $dirs.each |$k,$v| {
      tp::dir { $k:
        * => $dir_defaults + $v,
      }
    }
  } else {
    # Legacy code

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
        settings_hash        => $settings_hash,
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
    if $settings['brew_tap'] =~ String[1] {
      Package <| provider == tap |> -> Package <| provider == homebrew |>
      Package <| provider == tap |> -> Package <| provider == brew |>
      Package <| provider == tap |> -> Package <| provider == brewcask |>
      ensure_packages($settings['brew_tap'], { 'provider' => 'tap' })
    }

    if $settings[package_name] =~ Array and $manage_package {
      $package_defaults = {
        ensure   => $plain_ensure,
        provider => $package_provider,
      }
      $settings[package_name].each |$pkg| {
        package { $pkg:
          * => $package_defaults + pick($settings[package_params], {}),
        }
      }
    }
    if $settings[package_name] =~ String[1] and $manage_package {
      $package_defaults = {
        ensure          => $ensure,
        provider        => $package_provider,
        source          => $package_source,
        install_options => $package_install_options,
      }
      package { $settings[package_name]:
        * => $package_defaults + pick($settings[package_params], {}),
      }
    }

    if $settings[service_name] and $manage_service {
      $services_array=any2array($settings[service_name])
      $services_array.each |$svc| {
        $service_defaults = {
          ensure  => $service_ensure,
          enable  => $service_enable,
          require => $service_require,
        }
        service { $svc:
          * => $service_defaults + pick($settings[service_params], {}),
        }
      }
    }

    # Install straight from git source
    if $settings[git_source] {
      if ! $settings[package_name] or $settings[git_use] {
        tp::dir { $app:
          ensure  => $ensure,
          path    => pick ($settings[git_destination], "/opt/${app}"),
          source  => $settings[git_source],
          vcsrepo => 'git',
        }
      }
    }

    # Manage additional tp::conf as in conf_hash
    $conf_defaults = {
      'ensure'        => tp::ensure2file($ensure),
      'settings_hash' => $settings,
      'options_hash'  => $options_hash,
      'data_module'   => $data_module,
    }
    if $conf_hash != {} {
      $conf_hash.each |$k,$v| {
        tp::conf { $k:
          * => $conf_defaults + $v,
        }
      }
    }
    if $options_hash != {} and $settings[config_file_format] {
      tp::conf { $app:
        * => $conf_defaults,
      }
    }
    # Manage additional tp::dir as in dir_hash
    $dir_defaults = {
      'ensure'        => tp::ensure2dir($ensure),
      'settings_hash' => $settings,
      'data_module'   => $data_module,
    }
    if $dir_hash != {} {
      $dir_hash.each |$k,$v| {
        tp::dir { $k:
          * => $dir_defaults + $v,
        }
      }
    }

    # Automatically manage config files and any Puppet resource, if tinydata defined
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
        data_module  => $data_module,
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

    # Optional cli integration
    $tp_basedir = $facts['os']['family'] ? {
      'windows' => 'C:/ProgramData/PuppetLabs/tp',
      default   => '/etc/tp',
    }

    if $cli_enable and getvar('facts.identity.privileged') != false {
      file { "${tp_basedir}/app/${sane_app}":
        ensure  => $plain_ensure,
        content => inline_template('<%= @settings.to_yaml %>'),
      }
      file { "${tp_basedir}/shellvars/${sane_app}":
        ensure  => $plain_ensure,
        content => epp('tp/shellvars.epp', { settings => $settings }),
      }
      include tp
    }

    # Debugging
    if $debug == true {
      $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
      file { "tp_install_debug_${sane_app}":
        ensure  => $plain_ensure,
        content => $debug_scope,
        path    => "${debug_dir}/tp_install_debug_${sane_app}",
      }
    }
  }
}
