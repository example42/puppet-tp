# @define tp::service
#
# This define manages the service of the given app, creating the relevant
# service definition file (currently supported only systemd files)
#
# It's declared in tp::install::image, tp::install::source and tp::install:file
# defines to automatically create the service files for the installed apps.
# It's not expected to be declared directly.
#
# @param ensure What to do with the app service. When absent, service is stopped.
#
# @param on_missing_data What to do if tinydata is missing.
#
# @param settings The hash with all the apps settings.
#
# @param my_options An as of options used in the systemd_template
#
# @param manage_service If to manage the app's service
#
# @param mode The mode of the service. Can be 'docker' or 'normal'. With docker a
#   docker image is started and managed as a service.
#
# @param $systemd_template The template to use for the systemd service unit file.
#   The default is inifile_with_stanzas which gets the values from $my_options hash
#   merged with the internal $options_defaults hash.
#
# @param docker_image The container image to use, when mode is set to docker.
#
# @param command_path The full path of the command to use when starting the service.
#  In normal mode with systemd is the value of ExecStart
#
# @param systemd_symlink The symlink to systemd unit file under /lib/systemd/system.
#   If not set link will be /etc/systemd/system/multi-user.target.wants/${app}.service
#
define tp::service (
  Variant[Boolean,String] $ensure              = present,

  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

  Hash $settings                               = {},
  Hash $my_options                             = {},

  Boolean $manage_service                      = true,

  Enum['docker','normal'] $mode                = 'normal',

  Optional[String] $docker_image               = undef,
  Optional[Stdlib::Absolutepath] $command_path = undef,

  Optional[String] $systemd_symlink            = undef,

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')
  $real_command_path = pick ($command_path, "${tp::real_tp_params['destination']['path']}/${app}")

  case $facts['service_provider'] {
    'systemd': {
      if $mode == 'docker' {
        # Docker port mapping. Check tinydata/data/references for the available ports format
        case getvar('settings.image.ports') {
          # If settings.image.ports is undefined we map the main port in setting.ports
          undef: {
            $port_mapping = getvar('settings.ports.main.port') ? {
              undef   => '',
              default => "-p ${settings['ports']['main']['port']}:${settings['ports']['main']['port']}",
            }
          }
          String[0]: {
            $port_mapping = ''
          }
          Integer: {
            $port_mapping = "-p ${settings['image']['ports']}:${settings['image']['ports']}"
          }
          String[1]: {
            $port_mapping = "-p ${settings['image']['ports']}"
          }
          Array: {
            $port_mapping = join(getvar('settings.image.ports').map|$k| { "-p ${k}" }, ' ')
          }
          Hash: {
            $port_mapping = join(getvar('settings.image.ports').map |$k,$v| { "-p ${k}:${v}" }, ' ')
          }
          default: {
            tp::fail($on_missing_data, "tp::service ${app} - settings.image.ports is not a valid type")
          }
        }

        # Docker volumes or bind mounts mapping. Check tinydata/data/references for the available mounts format
        case getvar('settings.image.mounts') {
          # If settings.image.mounts is undefined we map all the dirs path in setting.dirs
          undef: {
            $mount_mapping = getvar('settings.dirs') ? {
              undef   => '',
              default => join(getvar('settings.dirs').map |$k,$v| { if getvar('v.path') { if getvar('os.selinux.enabled') { "-v ${v['path']}:${v['path']}:Z" } else { "-v ${v['path']}:${v['path']}" } } }, ' '), # lint:ignore:140chars
            }
          }
          String[0]: {
            $mount_mapping = ''
          }
          String[1]: {
            $mount_mapping = "-v ${settings['image']['mounts']}"
          }
          Array: {
            $mount_mapping = join(getvar('settings.image.mounts').map|$k| { if getvar('os.selinux.enabled') { "-v ${k}:${k}:Z" } else { "-v ${k}:${k}" } }, ' ') # lint:ignore:140chars
          }
          Hash: {
            $mount_mapping = join(getvar('settings.image.mounts').map |$k,$v| { if getvar('v.path') { if getvar('os.selinux.enabled') { "-v ${v['path']}:${v['path']}:Z" } else { "-v ${v['path']}:${v['path']}" } } }, ' ') # lint:ignore:140chars
          }
          default: {
            tp::fail($on_missing_data, "tp::service ${app} - settings.image.mounts is not a valid type")
          }
        }

        $docker_args = pick_default(getvar('settings.docker.args'),'')
        $cidfile = '%t/%n.ctr-id'
        $docker_command = $facts['os']['family'] ? {
          'RedHat' => '/usr/bin/podman',
          default  => '/usr/bin/docker',
        }
        $docker_after = $facts['os']['family'] ? {
          'RedHat' => 'network-online.target',
          default  => 'docker.service',
        }
        $docker_requires = $facts['os']['family'] ? {
          'RedHat' => 'network-online.target',
          default  => 'docker.service',
        }
        $options_defaults = {
          'Unit' => {
            'Description'   => pick(getvar('settings.description'),"${app} service"),
            'Documentation' => pick(getvar('settings.urls.documentation'),getvar('settings.urls.website'), "Search ${app}"),
            'After'         => $docker_after,
            'Requires'      => $docker_requires,
          },
          'Service' => {
            'ExecStartPre' => "/bin/rm -f ${cidfile}",
            'ExecStart'    => "${docker_command} run --rm --cidfile=${cidfile} --name ${app} ${docker_args} ${port_mapping} ${mount_mapping} ${docker_image}",
            'Restart'      => 'always',
            'RestartSec'   => '10s',
            'ExecStop'     => "${docker_command} stop --ignore --cidfile=${cidfile}",
            'ExecStopPost' => "${docker_command} rm -f --ignore --cidfile=${cidfile}",
          },
          'Install' => {
            'WantedBy' => 'multi-user.target',
          },
        }
      } else {
        $options_defaults = {
          'Unit' => {
            'Description'   => pick(getvar('settings.description'),"${app} service"),
            'Documentation' => pick(getvar('settings.urls.documentation'),getvar('settings.urls.website'),"Search ${app}"),
          },
          'Service' => {
            'ExecStart'       => $real_command_path,
            'Restart'         => 'always',
            'RestartSec'      => '10s',
            'User'            => pick(getvar('settings.service.main.process_user'),getvar('settings.process_user'),'root'),
            'Group'           => pick(getvar('settings.service.main.process_group'),getvar('settings.process_group'),'root'),
            'EnvironmentFile' => pick(getvar('settings.configs.init.path'),getvar('settings.init_file_path'),"/etc/default/${app}"), # lint:ignore:140chars
            'ExecReload'      => '/bin/kill -HUP $MAINPID',
          },
          'Install' => {
            'WantedBy' => 'multi-user.target',
          },
        }
      }
      $options = delete_undef_values($options_defaults.deep_merge($my_options))
      file { "/lib/systemd/system/${app}.service":
        ensure  => $ensure,
        path    => "/lib/systemd/system/${app}.service",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template(pick(getvar('settings.image.systemd_template'),'tp/inifile_with_stanzas.erb')),
        notify  => [Exec['tp systemctl daemon-reload'], Service[$app]],
      }
      $symlink_path = pick($systemd_symlink,"/etc/systemd/system/multi-user.target.wants/${app}.service") # lint:ignore:140chars
      file { $symlink_path:
        ensure => link,
        target => "/lib/systemd/system/${app}.service",
        notify => Exec['tp systemctl daemon-reload'],
        before => Service[$app],
      }
    }
    default: {
      tp::fail($on_missing_data, "tp::service ${app} - Service_provider ${facts['service_provider']} is not supported") # lint:ignore:140chars
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
