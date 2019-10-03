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
  String $check_service_command      = $::tp::params::check_service_command,
  String $check_service_command_post = $::tp::params::check_service_command_post,
  String $check_package_command      = $::tp::params::check_package_command,
  String $tp_dir                     = $::tp::params::tp_dir,
  String $ruby_path                  = $::tp::params::ruby_path,
  Hash $options_hash                 = {},
  Variant[Hash,Array[String]] $install_hash = {},
  Hash $conf_hash                    = {},
  Hash $dir_hash                     = {},
  Hash $concat_hash                  = {},
  Hash $stdmod_hash                  = {},
  Hash $puppi_hash                   = {},
  Hash $repo_hash                    = {},
  Boolean $purge_dirs                = false,
) inherits ::tp::params {

  contain ::tp::params

  $options_defaults = {
    'check_timeout'              => '10',
    'check_service_command'      => $check_service_command,
    'check_service_command_post' => $check_service_command_post,
    'check_package_command'      => $check_package_command,
  }
  $options = $options_defaults + $options_hash

  file { [ $tp_dir , "${tp_dir}/app" , "${tp_dir}/test" ]:
    ensure  => directory,
    mode    => '0755',
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
    mode    => '0755',
    content => template('tp/tp.erb'),
  }

  if $install_hash =~ Array {
    $install_hash.each | $name| { tp_install($name, {ensure => present}) }
  } else {
    $install_hash.each | $name, $options| { tp_install($name, $options) }
  }

  $conf_hash.each |$k,$v| {
    tp::conf { $k:
      * => $v,
    }
  }
  $dir_hash.each |$k,$v| {
    tp::dir { $k:
      * => $v,
    }
  }
  $concat_hash.each |$k,$v| {
    tp::concat { $k:
      * => $v,
    }
  }
  $stdmod_hash.each |$k,$v| {
    tp::stdmod { $k:
      * => $v,
    }
  }
  $repo_hash.each |$k,$v| {
    tp::repo { $k:
      * => $v,
    }
  }
}
