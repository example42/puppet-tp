#
define tp::service (
  Variant[Boolean,String] $ensure             = present,
  Hash $settings                              = {},
  Tp::Fail $on_missing_data    = pick($tp::on_missing_data,'notify'),
  Boolean $manage_service = true,
  Optional[Stdlib::Absolutepath] $command_path = undef,
  String[1] $data_module                      = 'tinydata',
  Enum['docker','normal'] $mode               = 'normal',
) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')
  $real_command_path = pick ($command_path, "${tp::cli::real_tp_params['destination']['path']}/${app}")

  case $facts['service_provider'] {
    'systemd': {
      if $mode == 'docker' {
        $docker_args = pick_default(getvar('settings.docker_args'),'')
        $options_defaults = {
          'Unit' => {
            'Description'   => pick(getvar('settings.description'),"${app} service"),
            'Documentation' => pick(getvar('settings.website'),"Search: ${app}"),
            'After'         => 'docker.service',
            'Requires'      => 'docker.service',
          },
          'Service' => {
            'ExecStartPre' => "-/usr/bin/docker stop ${app}",
            'ExecStartPre' => "-/usr/bin/docker rm ${app}",
            'ExecStartPre' => "/usr/bin/docker pull ${settings['docker_image']}",
            'ExecStart'    => "/usr/bin/docker run --rm --name ${app} ${docker_args} ${settings['docker_image']}",
            'Restart' => 'always',
            'RestartSec' => '10s',
          },
          'Install' => {
            'WantedBy' => 'multi-user.target',
          },
        }
      } else {
        $options_defaults = {
          'Unit' => {
            'Description' => pick(getvar('settings.description'),"${app} service"),
            'Documentation' => pick(getvar('settings.website'),"Search: ${app}"),
          },
          'Service' => {
            'ExecStart' => $real_command_path,
            'Restart' => 'always',
            'RestartSec' => '10s',
            'User' => pick(getvar('settings.process_user'), 'root'),
            'Group' => pick(getvar('settings.process_group'), 'root'),
            'EnvironmentFile' => pick(getvar('settings.init_file_path'),getvar('settings.configs.init.path'),"/etc/default/${app}"), # lint:ignore:140chars
            'ExecReload' => '/bin/kill -HUP $MAINPID',
          },
          'Install' => {
            'WantedBy' => 'multi-user.target',
          },
        }
      }
      $options = delete_undef_values($options_defaults.deep_merge(getvar('settings.install.systemd_settings', {})))
      file { "/lib/systemd/system/${app}.service":
        ensure  => $ensure,
        path    => "/lib/systemd/system/${app}.service",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('tp/inifile_with_stanzas.erb'),
        notify  => Exec['tp systemctl daemon-reload'],
        before  => Service[$app],
      }
      $symlink_path = pick(getvar('settings.install.systemd_symlink'),"/etc/systemd/system/multi-user.target.wants/${app}.service") # lint:ignore:140chars
      file { $symlink_path:
        ensure => link,
        target => "/lib/systemd/system/${app}.service",
        notify => Exec['tp systemctl daemon-reload'],
        before => Service[$app],
      }
    }
    default: {
      tp::fail($on_missing_data, "service_provider ${facts['service_provider']} is not supported")
    }
  }

  if $manage_service {
    service { $app:
      ensure    => tp::ensure2service($ensure,'ensure'),
      enable    => tp::ensure2service($ensure,'enable'),
      hasstatus => true,
    }
  }
}
