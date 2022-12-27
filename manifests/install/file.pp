# @define tp::install::file
#
# This define installs the application (app) set in the given title downloading
# the relevant file or tarball.
# The define takes care of:
# - Downloading the app file from the Internet (if a specific source is not given, tinydata is used)
# - Extracting the file (if the file is an archive)
# - Eventually building sources
# - Eventually installing the app's binary to destination path
# - Eventually create and manage the relevant service
#
# This define is declared from the tp::install define when $install_method is set
# to 'file'. You the tp::install argument 'params' to pass parameters to this define.
#
# @param ensure If to install (present), remove (absent), ensure is at latest
#   version (latest) or a specific one (1.1.1). Note: version can also be specified
#   via the version parameter. If that's set that takes prececendence over this one.
#
# @param on_missing_data What to do if tinydata is missing. Valid values are: ('emerg','')
#
# @param tp_params The tp_params hash to use. If not set, the global $tp::tp_params
#   is used.
#
# @param my_settings Custom settings hash. It's merged with and can
#   override the default tinydata settings key for the managed app
#
# @param my_build Custom build hash. It's merged with and can override
#   the default tinydata build key for the managed app
#
# @param auto_prereq If to automatically install the app's prerequisites
#   (if defined in tinydata)
#
# @param cli_enable If to enable the CLI for this app
#
# @param version The version to install. If not set, what's set in the ensure
#   parameter is used
#
# @param source The source URL to download the app from. If not set, the
#   URL is taken from tinydata
#
# @param destination The destination path where to install the app to.
#
# @param owner The owner of the app's downloaded and extracted files
#
# @param group The group of the app's downloaded and extracted files
#
# @param install If to install the app's binaries to destination
#
# @param manage_service If to manage the app's service
#
# @param data_module The module where to find the tinydata for the app
#
# @example Install an app from a release package. (Tinydaya must be present)
#   tp::install { 'prometheus':
#     install_method => 'file',
#   }
#
define tp::install::file (
  Variant[Boolean,String] $ensure             = present,

  Tp::Fail $on_missing_data    = pick($tp::on_missing_data,'notify'),

  Hash $tp_params                             = pick($tp::tp_params,{}),
  Hash $settings                              = {},

  Boolean $auto_prereq                        = pick($tp::auto_prereq, false),
  Boolean $cli_enable                         = true,

  Optional[String]               $version     = undef,
  Optional[String]               $source      = undef,
  Optional[Stdlib::Absolutepath] $destination = undef,
  String[1] $owner = pick(getvar('identity.user'),'root'),
  String[1] $group = pick(getvar('identity.group'),'root'),

  Optional[Boolean] $build                    = undef,
  Optional[Boolean] $install                  = undef,
  Boolean $manage_service                     = false,

  String[1] $data_module                      = 'tinydata',
) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  $tp_dir          = $tp::cli::real_tp_params['conf']['path']
  $destination_dir = $tp::cli::real_tp_params['destination']['path']
  $download_dir    = "${tp::cli::real_tp_params['data']['path']}/download/${app}"
  $extract_dir     = "${tp::cli::real_tp_params['data']['path']}/extract/${app}"

  $real_destination = pick($destination, "${destination_dir}/${app}")

  $retrieve_command = getvar('tp_params.settings.retrieve_command')
  $retrieve_args = getvar('tp_params.settings.retrieve_args')

  tp::create_dir { "tp::install::file - create_dir ${download_dir}":
    path   => $download_dir,
  }
  tp::create_dir { "tp::install::file - extract_dir ${extract_dir}":
    path => $extract_dir,
  }

  # Automatic dependencies management, if data defined
  if $auto_prereq and getvar('settings.releases.prerequisites') and $ensure != 'absent' {
    tp::create_everything ( getvar('settings.releases.prerequisites'), {})
  }

  # Download and unpack source
  if $version and $ensure != 'absent' {
    $real_version = $version
    $real_filename = pick(tp::url_replace(getvar('settings.releases.version.file_name'), $real_version), getvar('settings.releases.file_name'), $app) # lint-ignore: 140chars
  } elsif $ensure !~ /^present$|^latest$|^absent$/ {
    $real_version = $ensure
    $real_filename = pick(tp::url_replace(getvar('settings.releases.version.file_name'), $real_version), getvar('settings.releases.file_name'), $app) # lint-ignore: 140chars
  } elsif getvar('settings.releases.latest_version'){
    $real_version = getvar('settings.releases.latest_version')
    $real_filename = pick(tp::url_replace(getvar('settings.releases.version.file_name'), $real_version), getvar('settings.releases.file_name'), $app) # lint-ignore: 140chars
  } else {
    $real_version = ''
    tp::fail($on_missing_data, "tp::install::file - ${app} - No version specified and missing tinydata: settings.releases.latest_version")
  }
  if getvar('settings.releases.base_url') {
    $real_base_url = getvar('settings.releases.base_url')
  } else {
    tp::fail($on_missing_data, "tp::install::file - ${app} - Missing tinydata: settings.releases.base_url")
  }
  if getvar('settings.releases.version.base_path')or getvar('settings.releases.base_path') {
    $real_base_path = pick(getvar('settings.releases.version.base_path'), getvar('settings.releases.base_path'))
  } else {
    tp::fail($on_missing_data, "tp::install::file - ${app} - Missing tinydata: settings.releases.base_path or settings.releases.version.base_path") # lint-ignore: 140chars
  }
  $composed_url = "${real_base_url}/${real_base_path}${real_filename}" # lint-ignore: 140chars
  $real_url = tp::url_replace($composed_url, $real_version) # lint-ignore: 140chars
  $real_source = $ensure ? {
    'absent' => false,
    default  => pick($source, $real_url),
  }
  $extracted_dir = tp::url_replace(pick(getvar('settings.releases.extracted_dir'),getvar('settings.releases.version.extracted_dir'),basename($real_filename)), $real_version)  # lint-ignore: 140chars

  if $real_source {
    $source_filetype = pick(getvar('settings.releases.file_format'),'zip')
    $extract_command = getvar('tp_params.settings.extract_command') ? {
      '' => $source_filetype ? {
        'tgz'     => 'tar -zxf',
        'gz'      => 'tar -zxf',
        'tar.gz'  => 'tar -zxf',
        'bz2'     => 'tar -jxf',
        'tar'     => 'tar -xf',
        'zip'     => 'unzip',
        'binary'  => 'cp',
        default   => 'tar -zxf',
      },
      default => getvar('tp_params.settings.extract_command'),
    }

    $extract_command_second_arg = $extract_command ? {
      /^cp.*/    => '.',
      /^rsync.*/ => '.',
      default    => '',
    }

    $real_extracted_dir = basename($extracted_dir)

    $real_postextract_cwd = "${extract_dir}/${real_extracted_dir}"

    Exec {
      path        => $facts['path'],
      environment => pick(getvar('release.exec_environment'),[]),
      timeout     => pick(getvar('release.exec_timout'),'600'),
    }

    exec { "Downloading ${title} from ${real_source} to ${download_dir}":
      cwd     => $download_dir,
      command => "${retrieve_command} ${retrieve_args} ${real_source}",
      creates => "${download_dir}/${real_filename}",
      require => Tp::Create_dir["tp::install::file - create_dir ${download_dir}"],
    }

    if $extract_command {
      exec { "Extract ${real_filename} from ${download_dir} - ${title}":
        command => "mkdir -p ${extract_dir} && cd ${extract_dir} && ${extract_command} ${download_dir}/${real_filename} ${extract_command_second_arg}", # lint:ignore:140chars
        # unless  => "ls ${extract_dir}/${real_extracted_dir}",
        creates => "${extract_dir}/${real_extracted_dir}",
        require => [Exec["Downloading ${title} from ${real_source} to ${download_dir}"], Tp::Create_dir["tp::install::file - extract_dir ${extract_dir}"]], # lint:ignore:140chars
        notify  => Exec["Chown ${real_filename} in ${extract_dir} - ${title}"],
      }

      exec { "Chown ${real_filename} in ${extract_dir} - ${title}":
        command     => "chown -R ${owner}:${group} ${extract_dir}/${real_extracted_dir}",
        refreshonly => true,
        require     => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
      }
    }

    if pick($build, getvar('settings.build.enable'), false ) {
      if $auto_prereq and getvar('settings.build.prerequisites') {
        tp::create_everything ( getvar('settings.build.prerequisites'), {})
      }
      if getvar('settings.build.execs') {
        getvar('settings.build.execs').each | $c,$v | {
          $default_exec_params = {
            'cwd'         => $real_postextract_cwd,
            path          => $facts['path'],
          }
          exec { "${app} - tp::install::file build exec - ${c}":
            * => $default_exec_params + $v,
          }
        }
      }
    }

    if pick($install, getvar('settings.install.enable'), false ) {
      $files = getvar('settings.install.files', {})
      case $files {
        Hash: {
          $files.each | $k,$v | {
            file { "${destination_dir}/${k}":
              ensure  => $ensure,
              path    => "${destination_dir}/${k}",
              owner   => $owner,
              group   => $group,
              mode    => $v['mode'],
              source  => "file://${extract_dir}/${real_extracted_dir}/${k}",
              require => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
            }
          }
        }
        Array: {
          $files.each | $k | {
            file { "${destination_dir}/${k}":
              ensure  => $ensure,
              path    => "${destination_dir}/${k}",
              owner   => $owner,
              group   => $group,
              source  => "file://${extract_dir}/${real_extracted_dir}/${k}",
              require => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
            }
          }
        }
        String: {
          file { "${destination_dir}/${files}":
            ensure  => $ensure,
            path    => "${destination_dir}/${files}",
            owner   => $owner,
            group   => $group,
            source  => "file://${extract_dir}/${real_extracted_dir}/${files}",
            require => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
          }
        }
        default: {
          tp::fail($on_missing_data, 'tp::install::cli missing tinydata: settings.install.files is not a Hash, Array or String') # lint:ignore:140chars
        }
      }
      if getvar('settings.install.resources') and $ensure != 'absent' {
        tp::create_everything ( getvar('settings.install.resources'), {})
      }
      if $manage_service {
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

            $options = $options_defaults + getvar('settings.install.systemd_settings', {})
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
            $symlink_path = pick(getvar('settings.install.systemd_symlink'),"/etc/systemd/system/multi-user.target.wants/${app}.service") # lint:ignore:140chars
            file { $symlink_path:
              ensure => $link,
              target => "/lib/systemd/system/${app}.service",
              notify => Exec['tp systemctl daemon-reload'],
              before => Service[$app],
            }
            service { $app:
              ensure    => tp::ensure2service($ensure,'ensure'),
              enable    => tp::ensure2service($ensure,'enable'),
              hasstatus => true,
            }
          }
          default: {
            tp::fail($on_missing_data, "service_provider ${service_provider} is not supported")
          }
        }
      }
    }
  } else {
    tp::fail($on_missing_data, "tp::install::file missing parameter source or tinydata: settings.releases.base_url, settings.releases.[version].base_path, settings.releases.[version].filename}") # lint:ignore:140chars
  }

  if $cli_enable {
    tp::test { "${app}_file":
      ensure  => $ensure,
      content => "ls -l ${download_dir}/${real_filename}",
    }
  }
}
