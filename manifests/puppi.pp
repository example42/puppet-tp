#
#
# = Define: tp::puppi
#
# Manages Puppi integration
# Usage of this define is optional.
# When used, it requires Puppi.
# 
# == Parameters
#
define tp::puppi (

  $ensure         = present,

  $check_enable   = true ,
  $check_template = 'tp/puppi/check.erb',

  $info_enable    = true ,
  $info_template  = 'tp/puppi/info.erb',
  $info_defaults  = true,

  $log_enable     = true ,

  $options_hash   = { },
  $settings_hash  = { },

  $data_module    = 'tp',

  $verbose        = false,

  ) {

  # If we use tp::puppi we need puppi
  include puppi

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

  # Default options and computed variables
  $puppi_defaults = {
    check_timeout          => '10',

    check_process_command  => 'check_procs',
    check_process_critical => '1:',
    check_process_warning  => '1:',
    check_process_metric   => 'PROCS',

    check_service_command  => 'service',

    check_port_command     => 'check_tcp',
    check_port_critical    => '10',
    check_port_warning     => '5',
    check_port_host        => '127.0.0.1',
  }

  $puppi_options = merge($puppi_defaults, $options_hash)

  $real_check_base_dir = pick($puppi_options[check_command_base_dir],$::puppi::checkpluginsdir)

  $real_check_process_command = $puppi_options[check_process_command] ? {
    'check_procs' => "${real_check_base_dir}/${puppi_options[check_process_command]} \
       -c ${puppi_options[check_process_critical]} \
       -w ${puppi_options[check_process_warning]} \
       -m ${puppi_options[check_process_metric]} \
       -C ${settings[process_name]} \
      ",
    default       => "${real_check_base_dir}/${puppi_options[check_process_command]}",
  }

  $real_check_service_command = $puppi_options[check_service_command] ? {
    'service' => "service ${settings[service_name]} status",
    default   => $puppi_options[check_service_command],
  }

  $real_check_port_command = $puppi_options[check_port_command] ? {
    'check_tcp' => "${real_check_base_dir}/${puppi_options[check_port_command]} \
       -H ${puppi_options[check_port_host]} \
       -c ${puppi_options[check_port_critical]} \
       -w ${puppi_options[check_port_warning]} \
       -p ${settings[tcp_port]} \
     ",
    default     => "${real_check_base_dir}/${puppi_options[check_port_command]}",
  }

  $array_package_name=any2array($settings['package_name'])
  $array_service_name=any2array($settings['service_name'])
  $array_log_file_path=any2array($settings['log_file_path'])
  $array_tcp_port=any2array($settings['tcp_port'])
  $array_info_commands=any2array($settings['info_commands'])

  # Puppi checks
  if $check_enable == true {
    file { "${::puppi::params::checksdir}/${title}":
      ensure  => $ensure,
      mode    => '0755',
      owner   => $::puppi::params::configfile_owner,
      group   => $::puppi::params::configfile_group,
      require => Class['puppi'],
      content => template($check_template),
      tag     => 'tp_puppi_check',
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
        content => inline_template('<% @infos.each do |cmd| %><%= cmd %><% end %>'),
        tag     => 'tp_puppi_info',
      }
    }
  }


  # Puppi log
  if $log_enable == true {
    $logs = any2array($settings[log_file_path])
    file { "${::puppi::params::logsdir}/${title}":
      ensure  => $ensure,
      mode    => '0750',
      owner   => $::puppi::params::configfile_owner,
      group   => $::puppi::params::configfile_group,
      require => Class['puppi'],
      content => inline_template('<% @logs.each do |path| %><%= path %><% end %>'),
      tag     => 'tp_puppi_log',
    }
  }

}
