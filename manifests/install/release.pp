# @define tp::install::release
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
# @param settings The tinydata settings to use merged with params managed in tp::install
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
#
define tp::install::release (
  Variant[Boolean,String] $ensure             = present,

  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

  Hash $tp_params                             = pick($tp::tp_params, {}),
  Hash $settings                              = {},

  Boolean $auto_prereq                        = pick($tp::auto_prereq, false),

  Optional[String]               $version     = undef,
  Optional[String]               $source      = undef,
  Optional[Stdlib::Absolutepath] $destination = undef,
  String[1] $owner = pick(getvar('identity.user'),'root'),
  String[1] $group = pick(getvar('identity.group'),'root'),

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  $tp_dir          = $tp::real_tp_params['conf']['path']
  $destination_dir = $tp::real_tp_params['destination']['path']
  $download_dir    = "${tp::real_tp_params['data']['path']}/download/${app}"
  $extract_dir     = pick(getvar('settings.release.extract_dir'),"${tp::real_tp_params['data']['path']}/extract/${app}")

  $real_destination = pick($destination, "${destination_dir}/${app}")

  $retrieve_command = getvar('tp_params.settings.retrieve_command')
  $retrieve_args = getvar('tp_params.settings.retrieve_args')

  tp::create_dir { "tp::install::release - create_dir ${download_dir}":
    path   => $download_dir,
  }
  tp::create_dir { "tp::install::release - extract_dir ${extract_dir}":
    path => $extract_dir,
  }

  # Automatic dependencies management, if data defined
  if $auto_prereq and getvar('settings.release.prerequisites') and $ensure != 'absent' {
    tp::create_everything ( getvar('settings.release.prerequisites'), {})
  }

  # Download and unpack source
  $real_version = tp::get_version($ensure,$version,$settings)
  $real_majversion = tp::get_version($ensure,$version,$settings,'major')
  $real_filename = pick(tp::url_replace(pick(getvar('settings.release.file_name'),$app), $real_version, $real_majversion), $app) # lint:ignore:140chars
  #$real_filename = tp::url_replace(pick(getvar('settings.release.file_name'), $app), $real_version, $real_majversion) # lint:ignore:140chars
  if getvar('settings.release.base_url') {
    $real_base_url = tp::url_replace(pick(getvar('settings.release.base_url'), $app), $real_version, $real_majversion)
    $real_url = "${real_base_url}/${real_filename}"
  } else {
    tp::fail($on_missing_data, "tp::install::release - ${app} - Missing tinydata: settings.release.base_url") # lint:ignore:140chars
  }

  $real_source = $ensure ? {
    'absent' => false,
    default  => pick_default($source, $real_url),
  }
  $extracted_dir = getvar('settings.release.extracted_dir') ? {
    String  => tp::url_replace(getvar('settings.release.extracted_dir'), $real_version, $real_majversion), # lint:ignore:140chars
    default => tp::url_replace(basename($real_filename), $real_version, $real_majversion),
  }
  $extracted_file = getvar('settings.release.extracted_file')

  if $real_source {
    $source_filetype = pick(getvar('settings.release.file_format'),'zip')
    $extract_command = getvar('tp_params.settings.extract_command') ? {
      '' => $source_filetype ? {
        'tgz'     => 'tar -zxf',
        'gz'      => 'tar -zxf',
        'tar.gz'  => 'tar -zxf',
        'xz'      => 'tar -xvf',
        'tar.xz'  => 'tar -xvf',
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
      environment => pick(getvar('release.exec_environment'), []),
      timeout     => pick(getvar('release.exec_timout'),'600'),
    }

    exec { "Downloading ${title} from ${real_source} to ${download_dir}":
      cwd     => $download_dir,
      command => "${retrieve_command} ${retrieve_args} ${real_source}",
      creates => "${download_dir}/${real_filename}",
      require => Tp::Create_dir["tp::install::release - create_dir ${download_dir}"],
    }

    if $extract_command {
      $extract_creates = $extracted_dir ? {
        ''      => "${extract_dir}/${extracted_file}",
        default => "${extract_dir}/${extracted_dir}",
      }
      exec { "Extract ${real_filename} from ${download_dir} - ${title}":
        command => "mkdir -p ${extract_dir} && cd ${extract_dir} && ${extract_command} ${download_dir}/${real_filename} ${extract_command_second_arg}", # lint:ignore:140chars
        creates => $extract_creates,
        require => [Exec["Downloading ${title} from ${real_source} to ${download_dir}"], Tp::Create_dir["tp::install::release - extract_dir ${extract_dir}"]], # lint:ignore:140chars
        notify  => Exec["Chown ${real_filename} in ${extract_dir} - ${title}"],
        before  => Tp::Setup["tp::install::release ${app}"],
      }

      exec { "Chown ${real_filename} in ${extract_dir} - ${title}":
        command     => "chown -R ${owner}:${group} ${extract_dir}/${extracted_dir}",
        refreshonly => true,
        require     => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
        before      => Tp::Setup["tp::install::release ${app}"],
      }
    }
  } else {
    tp::fail($on_missing_data, "tp::install::release ${app} - Missing parameter source or tinydata: settings.release.base_url, settings.release.[version].filename}") # lint:ignore:140chars
  }
}
