# @define tp::install::file
#
# This define installs the application (app) set in the given title.
# Installation is done downloading and eventually unpacking a file from the Internet.
#
# @example installation of a specific version of an app
# Note: the version MUST be a valid for the app and coherent with the tinydata releases key
#
define tp::install::file (

  Variant[Boolean,String] $ensure           = present,
  Tp::Fail $on_missing_data = pick($tp::on_missing_data,'notify'),

  Hash $tp_params                    = pick($tp::tp_params,{}),

  Hash                    $my_settings      = {},
  Hash                    $my_releases      = {},

  Boolean                 $auto_prereq      = false,

  Optional[String]               $version             = undef,
  Optional[String]               $source              = undef,
  Optional[Stdlib::Absolutepath] $destination         = undef,

  Boolean $manage_service                    = false,

  String $retrieve_command                   = 'wget',
  String $retrieve_args       = '',

  String[1]               $data_module      = 'tinydata',

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  # Settings evaluation
  $tp_settings = tp_lookup4($app,'settings',$data_module,'merge')
  $settings = $tp_settings + $my_settings
  $tp_releases = tp_lookup4($app,'releases',$data_module,'merge')
  $releases = $tp_releases + $my_releases

  $tp_dir = $tp::cli::real_tp_params['conf']['path']

  $destination_dir = $tp::cli::real_tp_params['destination']['path']
  $download_dir    = "${tp::cli::real_tp_params['data']['path']}/download"
  $extract_dir     = "${tp::cli::real_tp_params['data']['path']}/extract"

  # Automatic dependencies management, if data defined
  if $auto_prereq and has_key($releases, 'prerequisites') and $ensure != 'absent' {
    tp::create_everything ( $releases['prerequisites'], {})
  }

  # Download and unpack source
  if $version and $ensure != 'absent' {
    $real_version = $version
    $real_filename = pick(tp::url_replace($releases['version']['file_name'], $real_version), getvar('releases.file_name'), $app) # lint-ignore: 140chars
  } elsif $ensure !~ /^present$|^latest$|^absent$/ {
    $real_version = $ensure
    $real_filename = pick(tp::url_replace($releases['version']['file_name'], $real_version), getvar('releases.file_name'), $app) # lint-ignore: 140chars
  } elsif getvar('releases.latest_version'){
    $real_version = getvar('releases.latest_version')
    $real_filename = pick(tp::url_replace($releases['version']['file_name'], $real_version), getvar('releases.file_name'), $app) # lint-ignore: 140chars
  } else {
    $real_filename = pick(tp::url_replace($releases['version']['file_name'], $real_version), getvar('releases.file_name'), $app) # lint-ignore: 140chars
    tp::fail($on_missing_data, "tp::install::file - ${app} - No version specified and missing tinydata: releases.latest_version")
  }
  $composed_url = "${releases['base_url']}/${releases['version']['base_path']}${real_filename}" # lint-ignore: 140chars
  $real_url = tp::url_replace($composed_url, $real_version) # lint-ignore: 140chars
  $real_source = $ensure ? {
    'absent' => false,
    default => pick($source, $real_url),
  }

  if $real_source {
    $source_filetype = pick(getvar('releases.file_format'),'zip')
    $source_dirname = pick(getvar('releases.version.extracted_dir'),getvar('releases.extracted_dir'),$real_filename)
    $extract_command = getvar('releases.extract_command') ? {
      ''      => $source_filetype ? {
        'tgz'     => 'tar -zxf',
        'gz'      => 'tar -zxf',
        'tar.gz'  => 'tar -zxf',
        'bz2'     => 'tar -jxf',
        'tar'     => 'tar -xf',
        'zip'     => 'unzip',
        'binary'  => 'cp',
        default   => 'tar -zxf',
      },
      default => getvar('releases.extract_command'),
    }

    $extract_command_second_arg = $extract_command ? {
      /^cp.*/    => '.',
      /^rsync.*/ => '.',
      default    => '',
    }

    $real_extracted_dir = getvar('releases.extract_command') ? {
      ''      => $extract_command ? {
        /(^cp.*|^rsync.*)/         => $real_filename,
        /(^tar -zxf*|^tar -jxf*)/  => regsubst($source_dirname,'.tar',''),
        default                    => $source_dirname,
      },
      default => $extracted_dir,
    }

    $real_postextract_cwd = $postextract_cwd ? {
      ''      => "${extract_dir}/${real_extracted_dir}",
      default => $postextract_cwd,
    }

    $real_creates = $creates ? {
      undef   => "${extract_dir}/${real_extracted_dir}",
      default => $creates,
    }

    Exec {
      path        => $facts['path'],
      environment => pick(getvar('release.exec_environment'),[]),
      timeout     => pick(getvar('release.exec_timout'),'600'),
    }
    exec { "Downloading ${title} from ${real_source} to ${download_dir}":
      cwd     => $download_dir,
      command => "${retrieve_command} ${retrieve_args} ${real_source}",
      creates => "${download_dir}/${real_filename}",
    }

    if $extract_command {
      exec { "Extract ${real_filename} from ${download_dir} - ${title}":
        command => "mkdir -p ${extract_dir} && cd ${extract_dir} && ${extract_command} ${download_dir}/${real_filename} ${extract_command_second_arg}", # lint:ignore:140chars
        unless  => "ls ${extract_dir}/${real_extracted_dir}",
        creates => $real_creates,
        require => Exec["Downloading ${title} from ${real_source} to ${download_dir}"],
        notify  => Exec["Chown ${real_filename} in ${extract_dir} - ${title}"],
      }

      exec { "Chown ${real_filename} in ${extract_dir} - ${title}":
        command     => "chown -R ${owner}:${group} ${extract_dir}/${real_extracted_dir}",
        refreshonly => true,
        require     => Exec["Extract ${real_filename} from ${download_dir} - ${title}"],
      }
    }
  }
}
