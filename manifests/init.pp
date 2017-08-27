#
# Class: tp
#
# This class provides hiera data entry points to create tp resources
# and tp commands to interact with applications installed via tp.
# If you don't use them, you don't need to include
# this class 
#
class tp (
  String $tp_path,
  String $tp_owner,
  String $tp_group,
  String $check_service_command,
  String $check_package_command,
  String $tp_dir,
  String $ruby_path,
  Hash $options_hash,

  Hash $install_hash,
  Hash $conf_hash,
  Hash $dir_hash,
  Hash $concat_hash,
  Hash $stdmod_hash,
  Hash $puppi_hash,
  Hash $repo_hash,

) {

  $options_defaults = {
    check_timeout          => '10',
    check_service_command  => $check_service_command,
    check_package_command  => $check_package_command,
  }
  $options = $options_defaults + $options_hash

  file { [ $tp_dir , "${tp_dir}/app" , "${tp_dir}/test" ]:
    ensure => directory,
    mode   => '0755',
    owner  => $tp_owner,
    group  => $tp_group,
  }

  file { $tp_path:
    owner   => $tp_owner,
    group   => $tp_group,
    mode    => '0755',
    content => template('tp/tp.erb'),
  }

  if $install_hash != {} {
    $install_hash.each |$k,$v| {
      tp_install($k,$v)
    }
  }
  if $conf_hash != {} {
    $conf_hash.each |$k,$v| {
      tp::conf { $k:
        * => $v,
      }
    }
  }
  if $dir_hash != {} {
    $dir_hash.each |$k,$v| {
      tp::dir { $k:
        * => $v,
      }
    }
  }
  if $concat_hash != {} {
    $concat_hash.each |$k,$v| {
      tp::concat { $k:
        * => $v,
      }
    }
  }
  if $stdmod_hash != {} {
    $stdmod_hash.each |$k,$v| {
      tp::stdmod { $k:
        * => $v,
      }
    }
  }
  if $repo_hash != {} {
    $repo_hash.each |$k,$v| {
      tp::repo { $k:
        * => $v,
      }
    }
  }
}
