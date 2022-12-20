# Class: tp::cli
#
# This class installs the tp command line
class tp::cli (
  Enum['present','absent'] $ensure   = 'present',
  Stdlib::Absolutepath $tp_path      = '/usr/local/bin/tp',
  Hash $tp_params                    = {},
  Stdlib::Absolutepath $tp_dir       = '/etc/tp',
  Optional[String] $ruby_path        = undef,
  String $scritps_source             = 'puppet:///modules/tp/scripts/',
  Boolean $suppress_tp_warnings      = true,
  Boolean $suppress_tp_output        = false,

  Hash $options                      = {},

  Boolean $info_enable                   = true,
  String $info_package_command           = 'puppet resource package',
  Stdlib::Absolutepath $info_script_path = '/etc/tp/run_info.sh',
  String $info_script_template           = 'tp/run_info.sh.epp',
  String $info_source                    = 'puppet:///modules/tp/run_info/',

  Boolean $debug_enable                   = true,
  String $debug_package_command           = 'puppet resource package',
  Stdlib::Absolutepath $debug_script_path = '/etc/tp/run_debug.sh',
  String $debug_script_template           = 'tp/run_debug.sh.epp',
  String $debug_source                    = 'puppet:///modules/tp/run_debug/',

  Boolean $purge_dirs                                                = false,

  Boolean $cli_enable                                                = true,
) {
  $file_ensure = $ensure ? {
    'present' => 'file',
    'absent'  => 'absent',
  }
  $dir_ensure = $ensure ? {
    'present' => 'directory',
    'absent'  => 'absent',
  }

  if has_key($facts,'identity') {
    $real_cli_enable = $facts['identity']['privileged'] ? {
      false   => false,
      default => $cli_enable,
    }
  } else {
    $real_cli_enable = $cli_enable
  }
  if $real_cli_enable {
    # Legacy code
    $options_defaults = {
      'check_timeout'              => '10',
      'check_service_command'      => $check_service_command,
      'check_service_command_post' => $check_service_command_post,
      'check_package_command'      => $check_package_command,
      'check_repo_path'            => $check_repo_path,
      'check_repo_path_post'       => $check_repo_path_post,
      'info_package_command'       => $info_package_command,
      'info_script_path'           => $info_script_path,
      'debug_package_command'      => $debug_package_command,
      'debug_script_path'          => $debug_script_path,
    }
    $real_options = $options_defaults + $options

    $real_ruby_path = $ruby_path ? {
      undef   => $facts['aio_agent_version'] ? {
        undef   => '/usr/bin/env ruby',
        ''      => '/usr/bin/env ruby',
        default => $facts['os']['family'] ? {
          'windows' => 'C:/Program Files/Puppet Labs/Puppet/bin/ruby',
          default   => '/opt/puppetlabs/puppet/bin/ruby',
        },
      },
      default => $ruby_path,
    }

    if $real_cli_enable {
      $dirs = [$tp_dir , "${tp_dir}/app" , "${tp_dir}/shellvars" , "${tp_dir}/test", "${tp_dir}/info", "${tp_dir}/debug"]
      $dirs.each | $d | {
        file { $d:
          ensure  => $dir_ensure,
          mode    => $tp_params['mode'],
          owner   => $tp_params['owner'],
          group   => $tp_params['group'],
          purge   => $purge_dirs,
          force   => $purge_dirs,
          recurse => $purge_dirs,
        }
      }

      $epp_params = {
        'real_ruby_path' => $real_ruby_path,
        'options'        => $real_options,
        'suppress_tp_warnings' => $suppress_tp_warnings,
        'tp_dir'         => $tp_dir,
      }
      file { $tp_path:
        ensure  => $file_ensure,
        path    => $tp_path,
        mode    => $tp_params['mode'],
        owner   => $tp_params['owner'],
        group   => $tp_params['group'],
        content => epp('tp/tp.epp', $epp_params),
      }

      if $facts['os']['family'] == 'windows' {
        file { "${tp_path}.bat":
          ensure  => $file_ensure,
          mode    => $tp_params['mode'],
          owner   => $tp_params['owner'],
          group   => $tp_params['group'],
          content => epp('tp/tp.bat.epp'),
        }
      } else {
        file { '/usr/sbin/tp':
          ensure => link,
          target => $tp_path,
        }
      }

      file { 'Scripts dir':
        ensure  => $dir_ensure,
        path    => "${tp_dir}/scripts",
        mode    => $tp_params['mode'],
        owner   => $tp_params['owner'],
        group   => $tp_params['group'],
        source  => $scripts_source,
        recurse => true,
      }
      file { 'info scripts':
        ensure  => $dir_ensure,
        path    => "${tp_dir}/run_info",
        mode    => $tp_params['mode'],
        owner   => $tp_params['owner'],
        group   => $tp_params['group'],
        source  => $info_source,
        recurse => true,
      }
      file { 'package_info':
        ensure  => $file_ensure,
        mode    => '0755',
        path    => "${tp_dir}/run_info/package_info",
        content => epp('tp/run_info/package_info.epp'),
      }

      file { $info_script_path:
        ensure  => $file_ensure,
        path    => $info_script_path,
        mode    => $tp_params['mode'],
        owner   => $tp_params['owner'],
        group   => $tp_params['group'],
        content => epp($info_script_template,),
      }

      file { 'debug scripts':
        ensure => $dir_ensure,
        path   => "${tp_dir}/run_debug",
        mode   => $tp_params['mode'],
        owner  => $tp_params['owner'],
        group  => $tp_params['group'],
        source => $debug_source,
      }
      file { 'package_debug':
        ensure  => $file_ensure,
        mode    => '0755',
        path    => "${tp_dir}/run_debug/package_debug",
        content => epp('tp/run_debug/package_debug.epp'),
      }
      file { $debug_script_path:
        ensure  => $file_ensure,
        path    => $debug_script_path,
        mode    => $tp_params['mode'],
        owner   => $tp_params['owner'],
        group   => $tp_params['group'],
        content => epp($debug_script_template, { 'options' => $real_options }),
      }
    }
  }
}
