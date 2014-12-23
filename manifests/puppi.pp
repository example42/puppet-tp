#
#
# = Define: tp::puppi
#
# Manages Puppi integration
# Usage of this define is optional.
# When used, it requires Puppi.
# But sure to include puppi class before using
# the tp::puppi define.
# 
# == Parameters
#
define tp::puppi (

  $ensure         = present,

  $check_enable   = true ,

  $info_enable    = true ,
  $info_template  = 'tpdata/puppi/info.erb',
  $info_defaults  = true,

  $log_enable     = true ,

  $options_hash   = { },
 
  $settings_hash  = { },

  $data_module    = 'tp',

  $verbose        = false,

  ) {

  # Parameters validation
  validate_bool($check_enable)
  validate_bool($info_enable)
  validate_bool($info_defaults)
  validate_bool($log_enable)
  validate_bool($verbose)
  validate_hash($options_hash)
  validate_hash($settings_hash)


  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings=merge($tp_settings,$settings_hash)

  # Default options 
  $puppi_defaults = {
    check_timeout          = '10',

    check_process_command  = 'check_procs',
    check_process_critical = '1:',
    check_process_warning  = undef,
    check_process_metric   = 'PROCS',

    check_service_command  = 'service',

    check_port_command     = 'check_tcp',
    check_port_critical    = '10',
    check_port_warning     = '5',
  }

  $puppi_options = merge($puppi_defaults, $options_hash)

  $real_check_process_command = ${puppi_options[check_process_command]} ? {
    'check_procs' => "${puppi_options[check_process_command]} \
       -c ${puppi_options[check_process_critical]} \
       -w ${puppi_options[check_process_warning]} \
       -m ${puppi_options[check_process_metric]} \
      ",
    default       => ${puppi_options[check_process_command]},
  }

  $real_check_service_command = $puppi_options[check_service_command] ? {
    'service' => "service ${settings[service_name]} status",
    default   => $puppi_options[check_service_command],
  }

  $real_check_port_command = $puppi_options[check_port_command] ? {
    'check_tcp' => "${puppi_options[check_port_command]} \
       -H ${puppi_options[check_port_hostname]} \
       -c ${puppi_options[check_port_critical]} \
       -w ${puppi_options[check_port_warning]} \
       -p ${settings[port_name]} \
     ",
    default     => $puppi_options[check_port_command],
  }

  $real_check_base_dir = pick($puppi_options[check_command_base_dir],$nagios_plugins_dir)

  # Puppi checks
  if $check_enable == true {

    if $settings[tcp_port] {

      puppi::check { "${title}_port":
        description => "Check ${title} TCP port ${settings[tcp_port]}",
        command     => $real_check_port_command,
        base_dir    => $real_check_base_dir,
        hostwide    => true,
      }
    }

    if $settings[service_name] {
      puppi::check { "${title}_service":
        description => "Check ${title} service",
        command     => $real_check_service_command,
        base_dir    => $real_check_base_dir],
        hostwide    => true,
      }
    }

    if $settings[process_name] {
      puppi::check { "${title}_process":
        description => "Check ${title} process",
        command     => $real_check_process_command,
        base_dir    => $real_check_base_dir],
        hostwide    => true,
      }
    }
  }


  # Puppi info
  if $info_enable == true {
    if $info_defaults == true {
      file { "${::puppi::params::infodir}/${title}":
        ensure  => $ensure,
        mode    => '0750',
        owner   => $::puppi::params::configfile_owner,
        group   => $::puppi::params::configfile_group,
        require => Class['puppi'],
        content => template($info_template),
        tag     => 'tp_puppi_info',
      }
    }

    if $settings[info_commands] {
      $infos = any2array($settings[info_commands])
      file { "${::puppi::params::infodir}/${title}_extra":
        ensure  => $ensure,
        mode    => '0750',
        owner   => $::puppi::params::configfile_owner,
        group   => $::puppi::params::configfile_group,
        require => Class['puppi'],
        content => inline_template("<% @infos.each do |cmd| %><%= cmd %><% end %>"),
        tag     => 'tp_puppi_info',
      }
    }
  }


  # Puppi log
  if $log_enable == true {
    $logs = any2array($settings[log_file_path])
    file { "${::puppi::params::logdir}/${title}":
      ensure  => $ensure,
      mode    => '0750',
      owner   => $::puppi::params::configfile_owner,
      group   => $::puppi::params::configfile_group,
      require => Class['puppi'],
      content => inline_template("<% @logs.each do |path| %><%= path %><% end %>"),
      tag     => 'tp_puppi_log',
    }
  }

}
