#
#
# = Define: tp::test
#
# Creates test scripts to be executed in whatever way
# 
# == Parameters
#
define tp::test (

  $ensure              = present,

  $acceptance_template = 'tp/test/acceptance.erb',

  $options_hash        = { },
  $settings_hash       = { },

  $data_module         = 'tp',
  $base_dir            = '/etc/tp/test',

  $verbose             = false,

  ) {

  # Parameters validation
  validate_bool($verbose)
  validate_hash($options_hash)
  validate_hash($settings_hash)


  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings=merge($tp_settings,$settings_hash)

  # Default options and computed variables
  $options_defaults = {
    check_timeout          => '10',
    check_service_command  => "service ${settings[service_name]} status",
    check_package_command  => $::osfamily ? {
      'RedHat' => "rpm -q ${settings[package_name]}",
      'Debian' => "dpkg -l ${settings[package_name]}",
      default  => "puppet resource package ${settings[package_name]}"
    },
    check_port_command     => 'check_tcp',
    check_port_critical    => '10',
    check_port_warning     => '5',
    check_port_host        => '127.0.0.1',
  }

  $options = merge($options_defaults, $options_hash)

  $array_package_name=any2array($settings['package_name'])
  $array_service_name=any2array($settings['service_name'])
  $array_tcp_port=any2array($settings['tcp_port'])

  # TODO: Refine
  if ! defined('/etc/tp') {
    file { '/etc/tp/':
      ensure => directory,
      mode   => '0755',
      owner  => root,
      group  => root,
    }
  }

  if ! defined(File[$base_dir]) {
    file { $base_dir:
      ensure => directory,
      mode   => '0755',
      owner  => root,
      group  => root,
    }
  }

  file { "${base_dir}/${title}":
    ensure  => $ensure,
    mode    => '0755',
    owner   => root,
    group   => root,
    content => template($acceptance_template),
    tag     => 'tp_test',
  }

}
