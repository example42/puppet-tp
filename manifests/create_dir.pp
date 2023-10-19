# @summary Create a directory and its eventual parents
#
# @example Create the the directory /data/utils/bin
#    psick::tools::create_dir { '/data/utils/bin': }
#
# @param owner The owner of the created directory
# @param group The group of the created directory
# @param mode The mode of the created directory
# @param path The path of the dir to create. Default $title
define tp::create_dir (
  Optional[String] $owner    = undef,
  Optional[String] $group    = undef,
  Optional[Stdlib::Filemode] $mode     = undef,
  Stdlib::AbsolutePath $path = $title,
) {
  $mkdir_command = $facts['os']['family'] ? {
    'windows' => "New-Item -ItemType Directory -Force -Path '${path}'",
    default   => "mkdir -p '${path}'",
  }
  $command_provider = $facts['os']['family'] ? {
    'windows' => 'powershell',
    default   => undef,
  }

  exec { "Create directory ${title}":
    command  => $mkdir_command,
    path     => $facts['path'],
    creates  => $path,
    provider => $command_provider,
  }

  if $facts['os']['family'] != 'windows' {
    if $owner {
      exec { "chown ${owner} ${title}":
        command => "chown '${owner}' '${path}'",
        path    => $facts['path'],
        onlyif  => "[ \$(stat -c '%U' '${path}') != '${owner}' ]",
      }
    }
    if $group {
      exec { "chgrp ${group} ${title}":
        command => "chgrp '${group}' '${path}'",
        path    => $facts['path'],
        onlyif  => "[ \$(stat -c '%G' '${path}') != '${group}' ]",
      }
    }
    if $mode {
      exec { "chmod ${mode} ${title}":
        command   => "chmod '${mode}' '${path}'",
        path      => '/bin:/sbin:/usr/sbin:/usr/bin',
        onlyif    => "[ 0\$(stat -c '%a' '${path}') != '${mode}' ]",
      }
    }
  }
}
