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

  Hash                    $my_settings      = {},
  Hash                    $my_releases      = {},

  Boolean                 $auto_prereq      = false,

  Stdlib::Url             $source           = undef,
  Sdlib::Absolutepath $destination          = '/usr/local/sbin',

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
    $resource_defaults = {}
    $releases['prerequisites'].each |$resource,$params| {
      case $params {
        Hash: {
          $resource.each |$kk,$vv| {
            create_resources($resource, { $kk => {} }, $resource_defaults + $vv)
          }
        }
        Array: {
          create_resources($resource, { $resource_data.unique => {} }, $resource_defaults)
        }
        String: {
          create_resources($resource, { $resource_data => {} }, $resource_defaults)
        }
        Undef: {
          # do nothing
        }
        default: {
          fail("Unsupported type for ${resource_data}. Valid types are String, Array, Hash, Undef.")
        }
      }
    }
  }

  # Download and unpack the file
  case $ensure {
    'latest': {
      if has_key($releases, 'latest') {
        $real_source = pick($releases['latest']['url']
      } else {
        fail("No latest release defined for ${app}")
      }
    },
    'present': {
      $version = $releases['latest']
    },
    'absent': {
      $version = 'absent'
    },
  }

  if $real_source {
    exec { "Downloaded ${real_source} in ${destination} - ${title}":
      cwd         => $work_dir,
      command     => "${retrieve_command} ${retrieve_args} ${real_source}",
      creates     => "${work_dir}/${source_filename}",
      timeout     => $timeout,
      path        => $path,
      environment => $exec_env,
    }

  $source_filename = parse_url($url,'filename')
  $source_filetype = parse_url($url,'filetype')
  $source_dirname = parse_url($url,'filedir')

  $real_extract_command = $extract_command ? {
    ''      => $source_filetype ? {
      '.tgz'     => 'tar -zxf',
      '.gz'      => 'tar -zxf',
      '.bz2'     => 'tar -jxf',
      '.tar'     => 'tar -xf',
      '.zip'     => 'unzip',
      default    => 'tar -zxf',
    },
    default => $extract_command,
  }

  $extract_command_second_arg = $real_extract_command ? {
    /^cp.*/    => '.',
    /^rsync.*/ => '.',
    default    => '',
  }

  $real_extracted_dir = $extracted_dir ? {
    ''      => $real_extract_command ? {
      /(^cp.*|^rsync.*)/         => $source_filename,
      /(^tar -zxf*|^tar -jxf*)/  => regsubst($source_dirname,'.tar',''),
      default                    => $source_dirname,
    },
    default => $extracted_dir,
  }

  $real_postextract_cwd = $postextract_cwd ? {
    ''      => "${destination_dir}/${real_extracted_dir}",
    default => $postextract_cwd,
  }

  $real_creates = $creates ? {
    undef   => "${destination_dir}/${real_extracted_dir}",
    default => $creates,
  }

  if $preextract_command and $preextract_command != '' {
    exec { "PreExtract ${source_filename} in ${destination_dir} - ${title}":
      command     => $preextract_command,
      subscribe   => Exec["Retrieve ${url} in ${work_dir} - ${title}"],
      refreshonly => true,
      path        => $path,
      environment => $exec_env,
      timeout     => $timeout,
    }
  }

  exec { "Retrieve ${url} in ${work_dir} - ${title}":
    cwd         => $work_dir,
    command     => "${retrieve_command} ${retrieve_args} ${url}",
    creates     => "${work_dir}/${source_filename}",
    timeout     => $timeout,
    path        => $path,
    environment => $exec_env,
  }

  if $extract_command {
    exec { "Extract ${source_filename} from ${work_dir} - ${title}":
      command     => "mkdir -p ${destination_dir} && cd ${destination_dir} && ${real_extract_command} ${work_dir}/${source_filename} ${extract_command_second_arg}", # lint:ignore:140chars
      unless      => "ls ${destination_dir}/${real_extracted_dir}",
      creates     => $real_creates,
      timeout     => $timeout,
      require     => Exec["Retrieve ${url} in ${work_dir} - ${title}"],
      path        => $path,
      environment => $exec_env,
      notify      => Exec["Chown ${source_filename} in ${destination_dir} - ${title}"],
    }

    exec { "Chown ${source_filename} in ${destination_dir} - ${title}":
      command     => "chown -R ${owner}:${group} ${destination_dir}/${real_extracted_dir}",
      refreshonly => true,
      timeout     => $timeout,
      require     => Exec["Extract ${source_filename} from ${work_dir} - ${title}"],
      path        => $path,
      environment => $exec_env,
    }
  }

  if $postextract_command and $postextract_command != '' {
    exec { "PostExtract ${source_filename} in ${destination_dir} - ${title}":
      command     => $postextract_command,
      cwd         => $real_postextract_cwd,
      subscribe   => Exec["Extract ${source_filename} from ${work_dir} - ${title}"],
      refreshonly => true,
      timeout     => $timeout,
      require     => [Exec["Retrieve ${url} in ${work_dir} - ${title}"],Exec["Chown ${source_filename} in ${destination_dir} - ${title}"]],
      path        => $path,
      environment => $exec_env,
    }
  }












  }


}
