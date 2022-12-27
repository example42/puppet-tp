#
define tp::service (
  Variant[Boolean,String] $ensure             = present,
  Hash $settings                              = {},
  Tp::Fail $on_missing_data    = pick($tp::on_missing_data,'notify'),

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  case $facts['service_provider'] {
    'systemd': {
      $options_defaults = {
        'Unit' => {
          'Description' => pick(getvar('settings.description'),"${app} service"),
          'Documentation' => pick(getvar('settings.website'),"Search: ${app}"),
        },
        'Service' => {
          'ExecStart' => "${destination_dir}/${app}",
          'Restart' => 'always',
          'RestartSec' => '10s',
          'User' => pick(getvar('settings.process_user'), 'root'),
          'Group' => pick(getvar('settings.process_group'), 'root'),
          'EnvironmentFile' => pick(getvar('settings.init_file_path'),getvar('configs.init.path'),"/etc/default/${app}"), # lint:ignore:140chars
          'ExecReload' => '/bin/kill -HUP $MAINPID',
        },
        'Install' => {
          'WantedBy' => 'multi-user.target',
        },
      }

      $options = $options_defaults + getvar('releases.install.systemd_settings', {})
      file { "/lib/systemd/system/${app}.service":
        ensure  => $ensure,
        path    => "/lib/systemd/system/${app}.service",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('tp/inifile_with_stanzas.erb'),
        require => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
        notify  => Exec['tp systemctl daemon-reload'],
        before  => Service[$app],
      }
      $symlink_path = pick(getvar('releases.systemd_symlink'),"/etc/systemd/system/multi-user.target.wants/${app}.service") # lint:ignore:140chars
      file { $symlink_path:
        ensure => $link,
        target => "/lib/systemd/system/${app}.service",
        notify => Exec['tp systemctl daemon-reload'],
        before => Service[$app],
      }
    }
    default: {}
  }

  if $manage_service {
    service { $app:
      ensure    => tp::ensure2service($ensure,'ensure'),
      enable    => tp::ensure2service($ensure,'enable'),
      hasstatus => true,
    }
  }
}
