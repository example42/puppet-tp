#
#
# = Define: tp::puppi
#
# Manages Puppi integration
#
#
# == Parameters
#
define tp::puppi (

  $ensure         = present,

  $check_enable   = true ,
  $info_enable    = true ,
  $info_template  = 'tp/puppi/info.erb',

  $log_enable     = true ,

  $options_hash   = { },
 
  $settings_hash  = { },

  ) {

  validate_bool($check_enable)
  validate_bool($info_enable)
  validate_bool($log_enable)
  validate_hash($options_hash)
  validate_hash($settings_hash)


  # Settings
  $tp_settings=tp_lookup($title,'settings','merge')
  $settings=merge($tp_settings,$settings_hash)

  # Default options 
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
        base_dir    => $real_check_base_dir],
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


  # Puppi info
  if $info_enable == true {
    puppi::info::module { $title:
      description  => "Info about ${title}",
      packagename  => $settings[package_name],
      servicename  => $settings[service_name],
      processname  => $settings[process_name],
      configfile   => $settings[config_file_path],
      configdir    => $settings[config_dir_path],
      pidfile      => $settings[pid_file_path],
      datadir      => $settings[data_dir_path],
      logdir       => $settings[log_dir_path],
      protocol     => 'tcp',
      port         => $settings[tcp_port],
      templatefile => $info_template,
    }
  }


  # Puppi log
  if $log_enable == true {
    puppi::log { $title:
      description => "Logs of ${title}",
      log         => $settings[log_file],
    }
  }

}
