#
# Class: tp
#
# This class provides hiera data entry points to create tp resources
# and tp commands to interact with applications installed via tp.
# If you don't use them, you don't need to include
# this class 
#
class tp (
  $tp_path,
  $tp_owner,
  $tp_group,
  $check_service_command,
  $check_package_command,
  $tp_dir,
  $ruby_path,
  $options_hash        = { },

  $install_hash = {},
  $conf_hash    = {},
  $dir_hash     = {},
  $concat_hash  = {},
  $stdmod_hash  = {},
  $puppi_hash   = {},
  $repo_hash    = {},

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

  $install_hash.each |$k,$v| {
    tp_install($k,$v)
  }
  
  $conf_hash.each |$k,$v| {
    tp::conf { $k,
      * => $v,
    }
  }
  $dir_hash.each |$k,$v| {
    tp::dir { $k,
      * => $v,
    }
  }
  $concat_hash.each |$k,$v| {
    tp::concat { $k,
      * => $v,
    }
  }
  $stdmod_hash.each |$k,$v| {
    tp::stdmod { $k,
      * => $v,
    }
  }
  $repo_hash.each |$k,$v| {
    tp::repo { $k,
      * => $v,
    }
  }

}
