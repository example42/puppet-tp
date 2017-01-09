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
  $tinydata_dir,
  $ruby_path,
  $options_hash        = { },
) {

  $options_defaults = {
    check_timeout          => '10',
    check_service_command  => $check_service_command,
    check_package_command  => $check_package_command,
  }
  $options = merge($options_defaults,$options_hash)

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

  # Hiera lookup to tp parameters
  $install_hash = hiera_hash('tp::install_hash' , {} )
  $conf_hash    = hiera_hash('tp::conf_hash' , {} )
  $dir_hash     = hiera_hash('tp::dir_hash' , {} )
  $concat_hash  = hiera_hash('tp::concat_hash' , {} )
  $stdmod_hash  = hiera_hash('tp::stdmod_hash' , {} )
  $puppi_hash   = hiera_hash('tp::puppi_hash' , {} )
  $repo_hash    = hiera_hash('tp::repo_hash' , {} )

  $packages     = hiera_hash('tp::packages' , {} )
  $services     = hiera_hash('tp::services' , {} )
  $files        = hiera_hash('tp::files' , {} )

  if $install_hash != {} {
    $install_hash.each |$k,$v| {
      tp_install($k,$v)
    }
  }
  if $conf_hash != {} {
    create_resources('tp::conf', $conf_hash )
  }
  if $dir_hash != {} {
    create_resources('tp::dir', $dir_hash )
  }
  if $concat_hash != {} {
    create_resources('tp::concat', $concat_hash )
  }
  if $stdmod_hash != {} {
    create_resources('tp::stdmod', $stdmod_hash )
  }
  if $puppi_hash != {} {
    create_resources('tp::puppi', $puppi_hash )
  }
  if $repo_hash != {} {
    create_resources('tp::repo', $repo_hash )
  }
  if $packages != {} {
    create_resources('package', $packages )
  }
  if $services != {} {
    create_resources('service', $services )
  }
  if $files != {} {
    create_resources('file', $files )
  }

}
