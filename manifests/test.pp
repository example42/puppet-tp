#
#
# = Define: tp::test
#
# Creates test scripts to be executed in whatever way
#
# == Parameters
#
define tp::test (

  Variant[Boolean,String] $ensure              = present,

  String                  $template            = 'tp/test/acceptance.erb',

  Hash                    $options_hash        = { },
  Hash                    $settings_hash       = { },

  String[1]               $data_module         = 'tinydata',
  String[1]               $base_dir            = '/etc/tp/test',

  Boolean                 $verbose             = false,
  Boolean                 $cli_enable          = false,

  ) {

  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  # Default options and computed variables
  $options_defaults = {
    check_timeout          => '10',
    check_service_command  => "service ${settings[service_name]} status",
    check_package_command  => $settings['package_provider'] ? {
      'gem'   => "gem list -i ${settings[package_name]}",
      'pip'   => "pip show ${settings[package_name]}",
      default => $::osfamily ? {
        'RedHat' => "rpm -q ${settings[package_name]}",
        'Debian' => "dpkg -l ${settings[package_name]}",
        default  => "puppet resource package ${settings[package_name]}",
      },
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

  if $template != '' {
    file { "${base_dir}/${title}":
      ensure  => $ensure,
      mode    => '0755',
      owner   => root,
      group   => root,
      content => template($template),
      tag     => 'tp_test',
    }
  }

  # Options cli integration
  if $cli_enable {
    file { "/etc/tp/app/${title}":
      ensure  => $ensure,
      content => inline_template('<%= @settings.to_yaml %>'),
    }
    include ::tp
  }
}
