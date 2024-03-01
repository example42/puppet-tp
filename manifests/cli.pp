# Class: tp::cli
#
# This class installs the tp command line
class tp::cli (
  Enum['present','absent'] $ensure   = 'present',
  Boolean $manage_tp                 = true,
  Hash $tp_commands                  = pick($tp::tp_commands, {}),

  Hash $options                      = {},
  Boolean $purge_dirs                = true,
  Boolean $cli_enable                = pick($tp::cli_enable, true),

  String[1] $data_module = pick($tp::data_module,'tinydata'),
  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

) {
  $file_ensure = tp::ensure2file($ensure)
  $dir_ensure = tp::ensure2dir($ensure)

  $real_tp_params = $tp::real_tp_params

  $ruby_path = undef
  $scripts_source = 'puppet:///modules/tp/scripts/'
  $suppress_tp_warnings = true
  $suppress_tp_output = false

  $info_script_path = "${tp::tp_dir}/bin/run_info.sh"
  $info_script_template = pick(getvar('tp_commands.info.scripts.template'),'tp/run_info.epp')
  $info_source  = getvar('tp_commands.info.scripts.dir_source')

  $debug_script_path = "${tp::tp_dir}/bin/run_debug.sh"
  $debug_script_template = getvar('tp_commands.debug.scripts.template')
  $debug_source = getvar('tp_commands.debug.scripts.dir_source')

  if $cli_enable {
    $options_defaults = {
      'check_timeout'              => '10',
      'check_service_command'      => getvar('tp_commands.check.service.command'),
      'check_service_command_post' => getvar('tp_commands.service.post_command'),
      'check_package_command'      => getvar('tp_commands.check.package.command'),
      'check_repo_path'            => getvar('tp_commands.check.repo.path'),
      'check_repo_path_post'       => getvar('tp_commands.check.repo.path_post'),
      'info_package_command'       => getvar('tp_commands.info.package'),
      'info_script_path'           => $info_script_path,
      'debug_package_command'      => getvar('tp_commands.debug.package.command'),
      'debug_script_path'          => $debug_script_path,
    }
    $real_options = $options_defaults + $options

    $real_ruby_path = $ruby_path ? {
      undef   => getvar('facts.aio_agent_version') ? {
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
      mode    => $tp::tp_dirs_mode,
      owner   => $tp::tp_dirs_owner,
      group   => $tp::tp_dirs_group,
    }

    $dirs = [$tp::tp_dir , "${tp::tp_dir}/app" , "${tp::tp_dir}/shellvars" , "${tp::tp_dir}/test", "${tp::tp_dir}/info", "${tp::tp_dir}/debug"]
    $dirs.each | $d | {
      file { $d:
        ensure  => $dir_ensure,
        purge   => $purge_dirs,
        force   => $purge_dirs,
        recurse => $purge_dirs,
      }
    }
    $work_dirs = [$tp::data_dir, $tp::download_dir , $tp::extract_dir , $tp::flags_dir]
    $work_dirs.each | $d | {
      file { $d:
        ensure  => $dir_ensure,
#          purge   => $purge_dirs,
#          force   => $purge_dirs,
#          recurse => $purge_dirs,
      }
    }
    $epp_params = {
      'real_ruby_path'       => $real_ruby_path,
      'options'              => $real_options,
      'suppress_tp_warnings' => $suppress_tp_warnings,
      'suppress_tp_output'   => $suppress_tp_output,
      'tp_dir'               => $tp::tp_dir,
    }
    file { $tp::tp_path:
      path    => $tp::tp_path,
      content => epp('tp/tp.epp', $epp_params),
    }

    if $facts['os']['family'] == 'windows' {
      file { "${tp::tp_path}.bat":
        content => epp('tp/tp.bat.epp'),
      }
    } else {
      file { '/usr/sbin/tp':
        ensure => link,
        target => $tp::tp_path,
      }
    }

    file { 'bin dir':
      ensure  => $dir_ensure,
      path    => "${tp::tp_dir}/bin",
      source  => $real_tp_params['bin']['args']['source'],
      recurse => true,
    }
    file { 'info scripts':
      ensure  => $dir_ensure,
      path    => "${tp::tp_dir}/bin/run_info",
      source  => $info_source,
      recurse => true,
    }
    file { 'package_info':
      mode    => '0755',
      path    => "${tp::tp_dir}/bin/run_info/package_info",
      content => epp('tp/run_info/package_info.epp'),
    }

    file { $info_script_path:
      mode    => '0755',
      path    => $info_script_path,
      content => epp($info_script_template, { 'options' => $real_options }),
    }

    file { 'debug scripts':
      ensure => $dir_ensure,
      path   => "${tp::tp_dir}/bin/run_debug",
      source => $debug_source,
    }
    file { 'package_debug':
      mode    => '0755',
      path    => "${tp::tp_dir}/bin/run_debug/package_debug",
      content => epp('tp/run_debug/package_debug.epp'),
    }
    file { $debug_script_path:
      mode    => '0755',
      path    => $debug_script_path,
      content => epp($debug_script_template, { 'options' => $real_options }),
    }
  }
}
