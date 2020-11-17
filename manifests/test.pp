# tp::test
#
# Creates test scripts to check if the application managed
# by Tiny Puppet is runnign correctly.
#
define tp::test (

  Variant[Boolean,String] $ensure              = present,

  Variant[Undef,String,Array] $source          = undef,
  Variant[Undef,String,Array] $template        = undef,
  Variant[Undef,String]   $epp                 = undef,
  Variant[Undef,String]   $content             = undef,

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

  include tp

  # Default options and computed variables
  $options_defaults = {
    check_timeout          => '10',
    check_service_command  => "${::tp::check_service_command} ${settings[service_name]} ${::tp::check_service_command_post}",
    check_package_command  => $settings['package_provider'] ? {
      'gem'   => "gem list -i ${settings[package_name]}",
      'pip'   => "pip show ${settings[package_name]}",
      default => $::tp::check_package_command,
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

  $file_content = tp_content($content, $template, $epp)
  if $file_content != '' {
    file { "${base_dir}/${title}":
      ensure  => $ensure,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => $file_content,
      source  => $source,
      tag     => 'tp_test',
    }
  }

  # Options cli integration
  if $cli_enable {
    file { "/etc/tp/app/${title}":
      ensure  => $ensure,
      content => inline_template('<%= @settings.to_yaml %>'),
    }
  }
}
