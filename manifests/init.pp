#
# Class: tp
#
# This class provides hiera data entry points to create tp resources
# and tp commands to interact with applications installed via tp.
# If you don't use them, you don't need to include
# this class 
#
class tp (
  String $tp_path                    = $::tp::params::tp_path,
  String $tp_owner                   = $::tp::params::tp_owner,
  String $tp_group                   = $::tp::params::tp_group,
  String $tp_mode                    = $::tp::params::tp_mode,
  String $check_service_command      = $::tp::params::check_service_command,
  String $check_service_command_post = $::tp::params::check_service_command_post,
  String $check_package_command      = $::tp::params::check_package_command,
  String $check_repo_path            = $::tp::params::check_repo_path,
  String $check_repo_path_post       = $::tp::params::check_repo_path_post,
  String $tp_dir                     = $::tp::params::tp_dir,
  String $ruby_path                  = $::tp::params::ruby_path,
  Hash $options_hash                 = {},

#  Variant[Hash,Array[String]] $install_hash                 = {},
  Enum['first','hash','deep'] $install_hash_merge_behaviour = 'first',
  Hash $install_defaults                                    = {},

#  Variant[Hash,Array[String]] $osfamily_install_hash                 = {},
  Enum['first','hash','deep'] $osfamily_install_hash_merge_behaviour = 'first',
  Hash $osfamily_install_defaults                                    = {},

#  Hash $conf_hash                    = {}, # Looked up in code
  Enum['first','hash','deep'] $conf_hash_merge_behaviour = 'first',

#  Variant[Hash,Array[String]] $osfamily_conf_hash                   = {},
  Enum['first','hash','deep'] $osfamily_conf_hash_merge_behaviour    = 'first',
  Hash $osfamily_conf_defaults                                       = {},

#  Hash $dir_hash                     = {},
  Enum['first','hash','deep'] $dir_hash_merge_behaviour = 'first',

#  Hash $concat_hash                  = {},
  Enum['first','hash','deep'] $concat_hash_merge_behaviour = 'first',

#  Hash $stdmod_hash                  = {},
  Enum['first','hash','deep'] $stdmod_hash_merge_behaviour = 'first',

#  Hash $puppi_hash                   = {},
  Enum['first','hash','deep'] $puppi_hash_merge_behaviour = 'first',

#  Hash $repo_hash                    = {},
  Enum['first','hash','deep'] $repo_hash_merge_behaviour = 'first',

  Boolean $purge_dirs                = false,
) inherits ::tp::params {

  contain ::tp::params

  $options_defaults = {
    'check_timeout'              => '10',
    'check_service_command'      => $check_service_command,
    'check_service_command_post' => $check_service_command_post,
    'check_package_command'      => $check_package_command,
    'check_repo_path'            => $check_repo_path,
    'check_repo_path_post'       => $check_repo_path_post,
  }
  $options = $options_defaults + $options_hash

  file { [ $tp_dir , "${tp_dir}/app" , "${tp_dir}/test" ]:
    ensure  => directory,
    mode    => $tp_mode,
    owner   => $tp_owner,
    group   => $tp_group,
    purge   => $purge_dirs,
    force   => $purge_dirs,
    recurse => $purge_dirs,
  }

  file { $tp_path:
    ensure  => present,
    path    => $tp_path,
    owner   => $tp_owner,
    group   => $tp_group,
    mode    => $tp_mode,
    content => template('tp/tp.erb'),
  }

  if $::osfamily == 'windows' {
    file { "${tp_path}.bat":
      ensure  => present,
      owner   => $tp_owner,
      group   => $tp_group,
      mode    => $tp_mode,
      content => template('tp/tp.bat.erb'),
    }
  }

  $install_hash = lookup('tp::install_hash',Variant[Hash,Array[String]],$install_hash_merge_behaviour,{})
  if $install_hash =~ Array {
    $install_hash.each | $name | { tp_install($name, {ensure => present}) }
  } else {
    $install_hash.each | $name, $options | { tp_install($name, $options) }
  }

  $osfamily_install_hash = lookup('tp::osfamily_install_hash',Variant[Hash,Array[String]],$osfamily_install_hash_merge_behaviour,{})
  $osfamily_install_hash.each |$k,$v| {
    if $::osfamily == $k {

      if has_key($osfamily_install_defaults, $k) {
        $os_defaults = $osfamily_install_defaults[$k]
      } else {
        $os_defaults = {}
      }

      case $v {
        Array: {
          $v.each |$kk| {
            tp_install ($kk, $os_defaults)
          }
        }
        Hash: {
          $v.each |$kk,$vv| {
            tp::install($kk, $os_defaults + $vv)
          }
        }
        String: {
          tp_install ($v, $os_defaults)
        }
        default: {
          fail("Unsupported type for ${v}. Valid types are String, Array, Hash")
        }
      }
    }
  }

  $conf_hash = lookup('tp::conf_hash',Hash,$conf_hash_merge_behaviour,{})
  $conf_hash.each |$k,$v| {
    tp::conf { $k:
      * => $v,
    }
  }

  $osfamily_conf_hash = lookup('tp::osfamily_conf_hash',Variant[Hash,Array[String]],$osfamily_conf_hash_merge_behaviour,{})
  $osfamily_conf_hash.each |$k,$v| {
    if $::osfamily == $k {

      if has_key($osfamily_conf_defaults, $k) {
        $os_defaults = $osfamily_conf_defaults[$k]
      } else {
        $os_defaults = {}
      }

      case $v {
        Array: {
          $v.each |$kk| {
            tp::conf { $kk:
              * => $os_defaults,
            }
          }
        }
        Hash: {
          $v.each |$kk,$vv| {
            tp::conf { $kk:
              * => $os_defaults + $vv,
            }
          }
        }
        String: {
          tp::conf { $kk:
            * => $os_defaults,
          }
        }
        default: {
          fail("Unsupported type for ${v}. Valid types are String, Array, Hash")
        }
      }
    }
  }



  $dir_hash = lookup('tp::dir_hash',Hash,$dir_hash_merge_behaviour,{})
  $dir_hash.each |$k,$v| {
    tp::dir { $k:
      * => $v,
    }
  }

  $concat_hash = lookup('tp::concat_hash',Hash,$concat_hash_merge_behaviour,{})
  $concat_hash.each |$k,$v| {
    tp::concat { $k:
      * => $v,
    }
  }

  $stdmod_hash = lookup('tp::stdmod_hash',Hash,$stdmod_hash_merge_behaviour,{})
  $stdmod_hash.each |$k,$v| {
    tp::stdmod { $k:
      * => $v,
    }
  }

  $repo_hash = lookup('tp::repo_hash',Hash,$repo_hash_merge_behaviour,{})
  $repo_hash.each |$k,$v| {
    tp::repo { $k:
      * => $v,
    }
  }
}
