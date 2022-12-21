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
  Enum['fail','ignore','warn'] $data_fail_behaviour = pick($tp::data_fail_behaviour,'warn'),

  Hash                    $my_settings      = {},
  Hash                    $my_releases      = {},

  Boolean                 $auto_prereq      = false,

  Optional[String]               $version             = undef,
  Optional[String]               $source              = undef,
  Optional[Stdlib::Absolutepath] $destination         = undef,

  Stdlib::Absolutepath $destination_dir     = '/usr/local/sbin',
  Stdlib::Absolutepath $download_dir        = '/var/tp/download',
  Stdlib::Absolutepath $extract_dir         = '/var/tp/extract',

  Boolean $manage_service                    = false,

  String $retrieve_command                   = 'wget',

  String[1]               $data_module      = 'tinydata',

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  # Settings evaluation
  $tp_settings = tp_lookup4($app,'settings',$data_module,'merge')
  $settings = $tp_settings + $my_settings
  $tp_releases = tp_lookup4($app,'releases',$data_module,'merge')
  $releases = $tp_releases + $my_releases

  # Automatic dependencies management, if data defined
  if $auto_prereq and has_key($releases, 'prerequisites') and $ensure != 'absent' {
    tp::create_everything ( $releases['prerequisites'], {})
  }

  # Download and unpack source
  case $ensure {
    'latest': {
      if getvar('releases.latest.url') {
        $real_source = pick($source, $releases['latest']['url'])
      } else {
        tp::fail($data_fail_behaviour,"Missing tinydata releases.last_version, releases.latest.url or data for ${app}")
      }
    }
    'present': {
      if $version and getvar('releases.base_url') and getvar('releases.version.file_path') {
        $composed_url = "${releases['base_url']}${releases['version']['file_path']}"
        $versioned_url = tp::url_replace($composed_url, $version) # lint-ignore: 140chars
        $real_source = pick($source, $versioned_url)
      } elsif getvar('releases.last_version') {
        $composed_url = "${releases['base_url']}${releases['version']['file_path']}"
        $versioned_url = tp::url_replace($composed_url, $facts['os']['family'], $facts['os']['architecture'], $facts['kernel']) # lint-ignore: 140chars
        $real_source = pick($source, $versioned_url)
      } elsif getvar('releases.latest.url') {
        $real_source = pick($source, $releases['latest']['url'])
      } else {
        tp::fail($data_fail_behaviour,"Missing tinydata releases.last_version, releases.latest.url or data for ${app}")
      }
    }
    'absent': {
      $real_source = false
    }
    default: {
      if has_key($releases, 'version') {
        $versioned_url = tp::url_replace($releases['version']['url'], $ensure, $facts['os']['family'], $facts['os']['architecture'], $facts['kernel']) # lint-ignore: 140chars
        $real_source = pick($source, $versioned_url)
      } else {
        fail("No release ${ensure} defined for ${app}")
      }
    }
  }

  if $real_source {
    $source_filename = pick(getvar('releases.file_name'), basename(getvar('releases.version.file_path')))
    $source_filetype = pick(getvar('releases.file_format'),'zip')
    $source_dirname = pick(getvar('releases.version.extracted_dir'),getvar('releases.extracted_dir'),$source_filename)
    $real_extract_command = getvar('releases.extract_command') ? {
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

    $extract_command_second_arg = $real_extract_command ? {
      /^cp.*/    => '.',
      /^rsync.*/ => '.',
      default    => '',
    }

    $real_extracted_dir = getvar('releases.extract_command') ? {
      ''      => $real_extract_command ? {
        /(^cp.*|^rsync.*)/         => $source_filename,
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

    exec { "Downloading ${title} from ${real_source} to ${download_dir}":
      cwd         => $work_dir,
      command     => "${retrieve_command} ${retrieve_args} ${real_source}",
      creates     => "${download_dir}/${source_filename}",
      timeout     => $timeout,
      path        => $path,
      environment => $exec_env,
    }

    if $extract_command {
      exec { "Extract ${source_filename} from ${work_dir} - ${title}":
        command     => "mkdir -p ${extract_dir} && cd ${extract_dir} && ${real_extract_command} ${work_dir}/${source_filename} ${extract_command_second_arg}", # lint:ignore:140chars
        unless      => "ls ${extract_dir}/${real_extracted_dir}",
        creates     => $real_creates,
        timeout     => $timeout,
        require     => Exec["Downloading ${title} from ${real_source} to ${download_dir}"],
        path        => $path,
        environment => $exec_env,
        notify      => Exec["Chown ${source_filename} in ${extract_dir} - ${title}"],
      }

      exec { "Chown ${source_filename} in ${extract_dir} - ${title}":
        command     => "chown -R ${owner}:${group} ${extract_dir}/${real_extracted_dir}",
        refreshonly => true,
        timeout     => $timeout,
        require     => Exec["Extract ${source_filename} from ${work_dir} - ${title}"],
        path        => $path,
        environment => $exec_env,
      }
    }
  }
}
