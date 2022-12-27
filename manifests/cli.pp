# Class: tp::cli
#
# This class installs the tp command line
class tp::cli (
  Enum['present','absent'] $ensure   = 'present',
  Boolean $manage_tp                 = true,
  Hash $tp_params                    = pick($tp::tp_params,{}),
  Hash $tp_commands                  = lookup('tp::tp_commands',{}),

  Hash $options                      = {},
  Boolean $purge_dirs                = false,
  Boolean $cli_enable                = true,

  String[1] $data_module = pick($tp::data_module,'tinydata'),
  Tp::Fail $on_missing_data = pick($tp::on_missing_data,'notify'),

) {
  $file_ensure = tp::ensure2file($ensure)
  $dir_ensure = tp::ensure2dir($ensure)

  if has_key($facts,'identity') {
    $real_tp_params = $facts['identity']['privileged'] ? {
      false   => $tp_params['user'],
      default => $tp_params['global'],
    }
  } else {
    $real_tp_params = $tp_params['global']
  }

  $tp_path = $real_tp_params['tp']['path']
  $tp_dir = $real_tp_params['conf']['path']
  $destination_dir = $real_tp_params['destination']['path']
  $data_dir = $real_tp_params['data']['path']
  $download_dir = "${real_tp_params['data']['path']}/download"
  $extract_dir = "${real_tp_params['data']['path']}/extract"

  $ruby_path = undef
  $scripts_source = 'puppet:///modules/tp/scripts/'
  $suppress_tp_warnings = true
  $suppress_tp_output = false

  $info_script_path = "${tp_dir}/bin/run_info.sh"
  $info_script_template = pick(getvar('tp_commands.info.scripts.template'),'tp/run_info.epp')
  $info_source  = getvar('tp_commands.info.scripts.dir_source')

  $debug_script_path = "${tp_dir}/bin/run_debug.sh"
  $debug_script_template = getvar('tp_commands.debug.scripts.template')
  $debug_source = getvar('tp_commands.debug.scripts.dir_source')

  if $cli_enable {
    $options_defaults = {
      'check_timeout'              => '10',
      'check_service_command'      => getvar('tp_commands.check.service.command'),
      'check_service_command_post' => getvar('tp_commands.service.post_command'),
      'check_package_command'      => getvar('tp_commands.check.package.command'),
      'check_repo_path'            => getvar('tp_commands.check.repo.command'),
      'check_repo_path_post'       => getvar('tp_commands.check.repo.post_commandcommand'),
      'info_package_command'       => getvar('tp_commands.info.package'),
      'info_script_path'           => $info_script_path,
      'debug_package_command'      => getvar('tp_commands.debug.package.command'),
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

    File {
      ensure  => $file_ensure,
      mode    => $real_tp_params['mode'],
      owner   => $real_tp_params['owner'],
      group   => $real_tp_params['group'],
    }

    if $cli_enable {
      $dirs = [$tp_dir , "${tp_dir}/app" , "${tp_dir}/shellvars" , "${tp_dir}/test", "${tp_dir}/info", "${tp_dir}/debug"]
      $dirs.each | $d | {
        file { $d:
          ensure  => $dir_ensure,
          purge   => $purge_dirs,
          force   => $purge_dirs,
          recurse => $purge_dirs,
        }
      }
      $work_dirs = [$data_dir, $download_dir , $extract_dir]
      $work_dirs.each | $d | {
        file { $d:
          ensure  => $dir_ensure,
#          purge   => $purge_dirs,
#          force   => $purge_dirs,
#          recurse => $purge_dirs,
        }
      }
      $epp_params = {
        'real_ruby_path' => $real_ruby_path,
        'options'        => $real_options,
        'suppress_tp_warnings' => $suppress_tp_warnings,
        'tp_dir'         => $tp_dir,
      }
      file { $tp_path:
        path    => $tp_path,
        content => epp('tp/tp.epp', $epp_params),
      }

      if $facts['os']['family'] == 'windows' {
        file { "${tp_path}.bat":
          content => epp('tp/tp.bat.epp'),
        }
      } else {
        file { '/usr/sbin/tp':
          ensure => link,
          target => $tp_path,
        }
      }

      file { 'bin dir':
        ensure  => $dir_ensure,
        path    => "${tp_dir}/bin",
        source  => $real_tp_params['source'],
        recurse => true,
      }
      file { 'info scripts':
        ensure  => $dir_ensure,
        path    => "${tp_dir}/bin/run_info",
        source  => $info_source,
        recurse => true,
      }
      file { 'package_info':
        mode    => '0755',
        path    => "${tp_dir}/bin/run_info/package_info",
        content => epp('tp/run_info/package_info.epp'),
      }

      file { $info_script_path:
        mode    => '0755',
        path    => $info_script_path,
        content => epp($info_script_template, { 'options' => $real_options }),
      }

      file { 'debug scripts':
        ensure => $dir_ensure,
        path   => "${tp_dir}/bin/run_debug",
        source => $debug_source,
      }
      file { 'package_debug':
        mode    => '0755',
        path    => "${tp_dir}/bin/run_debug/package_debug",
        content => epp('tp/run_debug/package_debug.epp'),
      }
      file { $debug_script_path:
        path    => $debug_script_path,
        content => epp($debug_script_template, { 'options' => $real_options }),
      }
    }
  }
}
