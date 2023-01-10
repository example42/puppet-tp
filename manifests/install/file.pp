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

  Optional[String]               $version     = undef,
  Optional[String]               $source      = undef,
  Optional[Stdlib::Absolutepath] $destination = undef,
  String[1] $owner = pick(getvar('identity.user'),'root'),
  String[1] $group = pick(getvar('identity.group'),'root'),

  Optional[Boolean] $build                    = undef,
  Optional[Boolean] $install                  = undef,
  Optional[Boolean] $manage_service           = undef,
  Optional[Boolean] $manage_user              = undef,

  String[1] $data_module                      = 'tinydata',
) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  $tp_dir          = $tp::real_tp_params['conf']['path']
  $destination_dir = $tp::real_tp_params['destination']['path']
  $download_dir    = "${tp::real_tp_params['data']['path']}/download/${app}"
  $extract_dir     = "${tp::real_tp_params['data']['path']}/extract/${app}"

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
  $real_version = tp::get_version($ensure,$version,$settings)
  $real_filename = pick(tp::url_replace(getvar('settings.releases.version.file_name'), $real_version), getvar('settings.releases.file_name'), $app) # lint-ignore: 140chars

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
  $extracted_dir = getvar('settings.releases.version.extracted_dir') ? {
    String  => tp::url_replace(getvar('settings.releases.version.extracted_dir'), $real_version), # lint-ignore: 140chars
    default => tp::url_replace(basename($real_filename), $real_version),
  }
  $extracted_file = getvar('settings.releases.version.extracted_file')

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

    $real_postextract_cwd = "${extract_dir}/${extracted_dir}"

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
      $extract_creates = $extracted_dir ? {
        ''      => "${extract_dir}/${extracted_file}",
        default => "${extract_dir}/${extracted_dir}",
      }
      exec { "Extract ${real_filename} from ${download_dir} - ${title}":
        command => "mkdir -p ${extract_dir} && cd ${extract_dir} && ${extract_command} ${download_dir}/${real_filename} ${extract_command_second_arg}", # lint:ignore:140chars
        creates => $extract_creates,
        require => [Exec["Downloading ${title} from ${real_source} to ${download_dir}"], Tp::Create_dir["tp::install::file - extract_dir ${extract_dir}"]], # lint:ignore:140chars
        notify  => Exec["Chown ${real_filename} in ${extract_dir} - ${title}"],
      }

      exec { "Chown ${real_filename} in ${extract_dir} - ${title}":
        command     => "chown -R ${owner}:${group} ${extract_dir}/${extracted_dir}",
        refreshonly => true,
        require     => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
      }
    }

    if pick($build, getvar('settings.build.enable'), false)
    or pick($install, getvar('settings.install.enable'), false) {
      tp::build { $app:
        ensure          => $ensure,
        build_dir       => $real_postextract_cwd,
        on_missing_data => $on_missing_data,
        settings        => $settings,
        data_module     => $data_module,
        auto_prereq     => $auto_prereq,
        owner           => $owner,
        group           => $group,
        build           => $build,
        install         => $install,
        manage_user     => $manage_user,
      }
    }

    if pick($manage_service, getvar('settings.install.manage_service'), false ) {
      tp::service { $app:
        ensure          => $ensure,
        on_missing_data => $on_missing_data,
        settings        => $settings,
        my_options      => getvar('settings.install.systemd_options', {}),
      }
    }
  } else {
    tp::fail($on_missing_data, "tp::install::file ${app} - Missing parameter source or tinydata: settings.releases.base_url, settings.releases.[version].base_path, settings.releases.[version].filename}") # lint:ignore:140chars
  }
}
