# Class: tp
#
# This class is what you need to include. It provides:
# - Installation of tp command line on target node
# - Hiera data entry points, in the tp:: namespace to mannage tp resources
#
class tp (
  Enum['present','absent'] $ensure   = 'present',
  Boolean $use_v4                    = false,
  Boolean $cli_enable                = true,
  Boolean $purge_dirs                = false,
  String[1] $data_module             = 'tinydata',

  # tp 4 new entrypoints
  Tp::Fail  $on_missing_data     = 'notify',

  # Variant[Hash,Array[String],String] $command+s             = {},
  # Looked up in code based on $merge_behaviours and $resources_defaults
  Hash $merge_behaviours   = {},
  Hash $resources_defaults = {},

  # OSfamily specific entrypoints
  Hash $osfamily_resources                                                           = {},
  Optional[Enum['first','unique','hash','deep']] $osfamily_resources_merge_behaviour = undef,
  Hash $osfamily_resources_defaults                                                  = {},

  Hash $tp_params                    = {},
  Hash $tp_commands                  = {},
  Boolean $auto_prereq               = false,

  # Legacy params
  #Stdlib::Absolutepath $tp_path      = '/usr/local/bin/tp',
  String $tp_owner                   = 'root',
  String $tp_group                   = 'root',
  String $tp_mode                    = '0755',
  String $check_service_command      = 'puppet resource service',
  String $check_service_command_post = '',
  String $check_package_command      = 'puppet resource package',
  String $check_repo_path            = '',
  String $check_repo_path_post       = '',
  #Stdlib::Absolutepath $tp_dir       = '/etc/tp',
  Optional[String] $ruby_path        = undef,
  String $lib_source                 = 'puppet:///modules/tp/lib/',
  Boolean $suppress_tp_warnings      = true,
  Boolean $suppress_tp_output        = false,

  Boolean $info_enable                   = true,
  String $info_package_command           = 'puppet resource package',
  Stdlib::Absolutepath $info_script_path = '/etc/tp/run_info.sh',
  String $info_script_template           = 'tp/run_info.sh.epp',
  String $info_source                    = 'puppet:///modules/tp/run_info/',

  Boolean $debug_enable                   = true,
  String $debug_package_command           = 'puppet resource package',
  Stdlib::Absolutepath $debug_script_path = '/etc/tp/run_debug.sh',
  String $debug_script_template           = 'tp/run_debug.sh.epp',
  String $debug_source                    = 'puppet:///modules/tp/run_debug/',

  Hash $options_hash                 = {},

  Variant[Hash,Array[String],String] $install_hash                   = {},
  Enum['first','hash','deep'] $install_hash_merge_behaviour           = 'first',
  Hash $install_defaults                                             = {},

  Variant[Hash,Array[String],String] $osfamily_install_hash          = {},
  Enum['first','hash','deep'] $osfamily_install_hash_merge_behaviour  = 'first',
  Hash $osfamily_install_defaults                                    = {},

  Hash $conf_hash                                                    = {},
  Enum['first','hash','deep'] $conf_hash_merge_behaviour              = 'first',
  Hash $conf_defaults                                                = {},

  Hash $osfamily_conf_hash                                           = {},
  Enum['first','hash','deep'] $osfamily_conf_hash_merge_behaviour     = 'first',
  Hash $osfamily_conf_defaults                                       = {},

  Hash $dir_hash                                                     = {},
  Enum['first','hash','deep'] $dir_hash_merge_behaviour               = 'first',
  Hash $dir_defaults                                                 = {},

  Hash $concat_hash                                                  = {},
  Enum['first','hash','deep'] $concat_hash_merge_behaviour            = 'first',
  Hash $concat_defaults                                              = {},

  Hash $stdmod_hash                                                  = {},
  Enum['first','hash','deep'] $stdmod_hash_merge_behaviour            = 'first',
  Hash $stdmod_defaults                                              = {},

  Hash $puppi_hash                                                   = {},
  Enum['first','hash','deep'] $puppi_hash_merge_behaviour             = 'first',
  Hash $puppi_defaults                                               = {},

  Hash $repo_hash                                                    = {},
  Enum['first','hash','deep'] $repo_hash_merge_behaviour              = 'first',
  Hash $repo_defaults                                                = {},

) {
  $file_ensure = $ensure ? {
    'present' => 'file',
    'absent'  => 'absent',
  }
  $dir_ensure = $ensure ? {
    'present' => 'directory',
    'absent'  => 'absent',
  }

  deprecation('conf_hash', 'Replace with confs')
  deprecation('dir_hash', 'Replace with dirs')
  deprecation('settings_hash', 'Replace with my_settings')
  deprecation('options_hash', 'Replace with options')

  if has_key($facts,'identity') {
    $real_tp_params = $facts['identity']['privileged'] ? {
      false   => $tp_params['user'],
      default => $tp_params['global'],
    }
  } else {
    $real_tp_params = $tp_params['global']
  }
  $tp_path = $real_tp_params['tp']['path']
  $tp_dir = $real_tp_params['conf']['path']
  $destination_dir = $real_tp_params['destination']['path']
  $data_dir = $real_tp_params['data']['path']
  $download_dir = "${real_tp_params['data']['path']}/download"
  $extract_dir = "${real_tp_params['data']['path']}/extract"
  $flags_dir = "${real_tp_params['data']['path']}/flags"

  if $use_v4 {
    $resources = ['repo', 'install', 'uninstall', 'conf', 'dir', 'test', 'info', 'debug', 'image' , 'source' , 'desktop', 'build']
    # tp 4 new entrypoints
    $resources.each |$resource| {
      $resource_data = lookup("tp::${resource}s",Variant[Hash,Array[String],String,Undef],pick(getvar("merge_behaviours.${resource}",'first'),{})) # puppet-lint:ignore:140chars
      $resource_defaults = { data_module => $data_module } + getvar("resources_defaults.${resource}",{})
      case $resource_data {
        Hash: {
          $resource_data.each |$kk,$vv| {
            create_resources("tp::${resource}", { $kk => {} }, $resource_defaults + $vv)
          }
        }
        Array: {
          create_resources("tp::${resource}", { $resource_data.unique => {} }, $resource_defaults)
        }
        String: {
          create_resources("tp::${resource}", { $resource_data => {} }, $resource_defaults)
        }
        Undef: {
          # do nothing
        }
        default: {
          tp::fail($on_missing_data, "Missing data for tp::${resource}s : ${resource_data}. Expected: String, Array, Hash, Undef.")
        }
      }
    }

    $osfamily_resources.each |$k,$v| {
      if $facts['os']['family'] == $k {
        $v.each |$res,$val| {
          $res.each |$resource| {
            if $res == $resource {
              $resource_data = lookup("tp::${res}s",Variant[Hash,Array[String],String,Undef],pick(getvar("merge_behaviours.${res}",'first'),{}))
              $resource_defaults = { data_module => $data_module } + getvar("resources_defaults.${k}",{})
              case $resource_data {
                Hash: {
                  $resource_data.each |$kk,$vv| {
                    create_resources("tp::${resource}", $kk, $resource_defaults + $vv)
                  }
                }
                Array: {
                  $resource_data.unique.each |$kk| {
                    create_resources("tp::${resource}", { $kk => {} }, $resource_defaults)
                  }
                }
                String: {
                  create_resources("tp::${resource}", $resource_data, $resource_defaults)
                }
                Undef: {
                  # do nothing
                }
                default: {
                  fail("Unsupported type for ${resource_data}. Valid types are String, Array, Hash, Undef.")
                }
              }
            }
          }
        }
      }
    }
    if $cli_enable {
      include 'tp::cli'
    }

    exec { 'tp systemctl daemon-reload':
      command     => 'systemctl daemon-reload',
      refreshonly => true,
      path        => $facts['path'],
    }
  } else {
    # Legacy code
    $options_defaults = {
      'check_timeout'              => '10',
      'check_service_command'      => $check_service_command,
      'check_service_command_post' => $check_service_command_post,
      'check_package_command'      => $check_package_command,
      'check_repo_path'            => $check_repo_path,
      'check_repo_path_post'       => $check_repo_path_post,
      'info_package_command'       => $info_package_command,
      'info_script_path'           => $info_script_path,
      'debug_package_command'      => $debug_package_command,
      'debug_script_path'          => $debug_script_path,
    }
    $options = $options_defaults + $options_hash

    $real_ruby_path = $ruby_path ? {
      undef   => $facts['aio_agent_version'] ? {
        undef   => '/usr/bin/env ruby',
        ''      => '/usr/bin/env ruby',
        default => $facts['os']['family'] ? {
          'windows' => 'C:/Program Files/Puppet Labs/Puppet/bin/ruby',
          default   => '/opt/puppetlabs/puppet/bin/ruby',
        },
      },
      default => $ruby_path,
    }

    # Cli dirs and files
    if has_key($facts,'identity') {
      $real_cli_enable = $facts['identity']['privileged'] ? {
        false   => false,
        default => $cli_enable,
      }
    } else {
      $real_cli_enable = $cli_enable
    }
    if $real_cli_enable {
      file { [$tp_dir , "${tp_dir}/app" , "${tp_dir}/shellvars" , "${tp_dir}/test"]:
        ensure  => $dir_ensure,
        mode    => $tp_mode,
        owner   => $tp_owner,
        group   => $tp_group,
        purge   => $purge_dirs,
        force   => $purge_dirs,
        recurse => $purge_dirs,
      }
      file { $tp_path:
        ensure  => $file_ensure,
        path    => $tp_path,
        owner   => $tp_owner,
        group   => $tp_group,
        mode    => $tp_mode,
        content => template('tp/tp.erb'),
      }
      if $facts['os']['family'] == 'windows' {
        file { "${tp_path}.bat":
          ensure  => $file_ensure,
          owner   => $tp_owner,
          group   => $tp_group,
          mode    => $tp_mode,
          content => template('tp/tp.bat.erb'),
        }
      } else {
        file { '/usr/sbin/tp':
          ensure => link,
          target => $tp_path,
        }
      }

      if $info_enable {
        file { 'tp common libraries':
          ensure  => $dir_ensure,
          path    => "${tp_dir}/lib",
          owner   => $tp_owner,
          group   => $tp_group,
          mode    => $tp_mode,
          source  => $lib_source,
          recurse => true,
        }
        file { 'info dir':
          ensure => $dir_ensure,
          path   => "${tp_dir}/info",
          owner  => $tp_owner,
          group  => $tp_group,
          mode   => $tp_mode,
        }
        file { 'info scripts':
          ensure  => $dir_ensure,
          path    => "${tp_dir}/run_info",
          owner   => $tp_owner,
          group   => $tp_group,
          mode    => $tp_mode,
          source  => $info_source,
          recurse => true,
        }
        file { 'package_info':
          ensure  => $file_ensure,
          mode    => '0755',
          path    => "${tp_dir}/run_info/package_info",
          content => epp('tp/run_info/package_info.epp'),
        }
        file { $info_script_path:
          ensure  => $file_ensure,
          path    => $info_script_path,
          owner   => $tp_owner,
          group   => $tp_group,
          mode    => $tp_mode,
          content => epp($info_script_template, { 'options' => $options }),
        }
      }

      if $debug_enable {
        file { 'debug dir':
          ensure => $dir_ensure,
          path   => "${tp_dir}/debug",
          owner  => $tp_owner,
          group  => $tp_group,
          mode   => $tp_mode,
        }
        file { 'debug scripts':
          ensure  => $dir_ensure,
          path    => "${tp_dir}/run_debug",
          owner   => $tp_owner,
          group   => $tp_group,
          mode    => $tp_mode,
          source  => $debug_source,
          recurse => true,
        }
        file { 'package_debug':
          ensure  => $file_ensure,
          mode    => '0755',
          path    => "${tp_dir}/run_debug/package_debug",
          content => epp('tp/run_debug/package_debug.epp'),
        }
        file { $debug_script_path:
          ensure  => $file_ensure,
          path    => $debug_script_path,
          owner   => $tp_owner,
          group   => $tp_group,
          mode    => $tp_mode,
          content => epp($debug_script_template, { 'options' => $options }),
        }
      }
    }

    $install_hash_merged = $install_hash_merge_behaviour ? {
      'first' => $install_hash,
      default => lookup('tp::install_hash',Variant[Hash,Array[String]],$install_hash_merge_behaviour,{})
    }
    case $install_hash_merged {
      Array: {
        $install_hash_merged.each |$kk| {
          tp_install($kk, $install_defaults + { ensure => present })
        }
      }
      Hash: {
        $install_hash_merged.each |$kk,$vv| {
          tp_install($kk, $install_defaults + $vv)
        }
      }
      String: {
        tp_install($install_hash_merged, $install_defaults + { ensure => present })
      }
      default: {
        fail("Unsupported type for ${install_hash_merged}. Valid types are String, Array, Hash")
      }
    }

    $osfamily_install_hash_merged = $osfamily_install_hash_merge_behaviour ? {
      'first' => $osfamily_install_hash,
      default => lookup('tp::osfamily_install_hash',Variant[Hash,Array[String],String],$osfamily_install_hash_merge_behaviour,{})
    }
    $osfamily_install_hash_merged.each |$k,$v| {
      if $facts['os']['family'] == $k {
        if has_key($osfamily_install_defaults, $k) {
          $os_defaults = $osfamily_install_defaults[$k]
        } else {
          $os_defaults = {}
        }
        case $v {
          Array: {
            $v.each |$kk| {
              tp_install($kk, $os_defaults)
            }
          }
          Hash: {
            $v.each |$kk,$vv| {
              tp_install($kk, $os_defaults + $vv)
            }
          }
          String: {
            tp_install($v, $os_defaults)
          }
          default: {
            fail("Unsupported type for ${v}. Valid types are String, Array, Hash")
          }
        }
      }
    }

    # tp::conf
    $conf_hash_merged = $conf_hash_merge_behaviour ? {
      'first' => $conf_hash,
      default => lookup('tp::conf_hash',Hash,$conf_hash_merge_behaviour,{})
    }
    $conf_hash_merged.each |$k,$v| {
      tp::conf { $k:
        * => $conf_defaults + $v,
      }
    }

    $osfamily_conf_hash_merged = $osfamily_conf_hash_merge_behaviour ? {
      'first' => $osfamily_conf_hash,
      default => lookup('tp::osfamily_conf_hash',Hash,$osfamily_conf_hash_merge_behaviour,{})
    }
    $osfamily_conf_hash_merged.each |$k,$v| {
      if $facts['os']['family'] == $k {
        if has_key($osfamily_conf_defaults, $k) {
          $os_defaults = $osfamily_conf_defaults[$k]
        } else {
          $os_defaults = {}
        }
        $v.each |$kk,$vv| {
          tp::conf { $kk:
            * => $os_defaults + $vv,
          }
        }
      }
    }

    $dir_hash_merged = $dir_hash_merge_behaviour ? {
      'first' => $dir_hash,
      default => lookup('tp::dir_hash',Hash,$dir_hash_merge_behaviour,{})
    }
    $dir_hash_merged.each |$k,$v| {
      tp::dir { $k:
        * => $dir_defaults + $v,
      }
    }

    $concat_hash_merged = $concat_hash_merge_behaviour ? {
      'first' => $concat_hash,
      default => lookup('tp::concat_hash',Hash,$concat_hash_merge_behaviour,{})
    }
    $concat_hash_merged.each |$k,$v| {
      tp::concat { $k:
        * => $concat_defaults + $v,
      }
    }

    $stdmod_hash_merged = $stdmod_hash_merge_behaviour ? {
      'first' => $stdmod_hash,
      default => lookup('tp::stdmod_hash',Hash,$stdmod_hash_merge_behaviour,{})
    }
    $stdmod_hash_merged.each |$k,$v| {
      tp::stdmod { $k:
        * => $stdmod_defaults + $v,
      }
    }

    $puppi_hash_merged = $puppi_hash_merge_behaviour ? {
      'first' => $puppi_hash,
      default => lookup('tp::puppi_hash',Hash,$puppi_hash_merge_behaviour,{})
    }
    $puppi_hash.each |$k,$v| {
      tp::puppi { $k:
        * => $puppi_defaults + $v,
      }
    }

    $repo_hash_merged = $repo_hash_merge_behaviour ? {
      'first' => $repo_hash,
      default => lookup('tp::repo_hash',Hash,$repo_hash_merge_behaviour,{})
    }
    $repo_hash.each |$k,$v| {
      tp::repo { $k:
        * => $repo_defaults + $v,
      }
    }
  }
}
