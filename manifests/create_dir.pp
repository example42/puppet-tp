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
  Optional[String] $mode     = undef,
  Stdlib::AbsolutePath $path = $title,
) {
  exec { "mkdir -p ${title}":
    command => "mkdir -p ${path}",
    path    => $facts['path'],
    creates => $path,
  }
  if $owner {
    exec { "chown ${owner} ${title}":
      command => "chown ${owner} ${path}",
      path    => $facts['path'],
      onlyif  => "[ $(ls -ld ${path} | awk '{ print \$3 }') != ${owner} ]",
    }
  }
  if $group {
    exec { "chgrp ${group} ${title}":
      command => "chgrp ${group} ${path}",
      path    => $facts['path'],
      onlyif  => "[ $(ls -ld ${path} | awk '{ print \$4 }') != ${group} ]",
    }
  }
  if $mode {
    exec { "chmod ${mode} ${title}":
      command     => "chmod ${mode} ${path}",
      path        => $facts['path'],
      subscribe   => Exec["mkdir -p ${title}"],
      refreshonly => true,
    }
  }
}
