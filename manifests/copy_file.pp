# @summary Copies a file from source to destination
#
# This defines copied a file from a source to a destination
# using an exec resource. It does not overwrite the destination
# file if it exists (and overwrite is set to true) and can be
# used as alternative to a file resource to avoid duplicated
# resources.
#
# @param source The source of the file to copy (must be a valid path)
# @param owner The owner of the created file
# @param group The group of the created file
# @param mode The mode of the created file
# @param path The path of the file to create. Default $title
# @param source The source file to copy
define tp::copy_file (
  Stdlib::AbsolutePath $source,
  Enum['present','absent'] $ensure = 'present',
  Stdlib::AbsolutePath $path       = $title,
  Optional[String] $owner          = undef,
  Optional[String] $group          = undef,
  Optional[String] $mode           = undef,
  Boolean $overwrite               = false,
) {
  if $overwrite {
    $exec_creates = undef
    $exec_unless  = "diff ${source} ${path} >/dev/null"
  } else {
    $exec_creates = $path
    $exec_unless  = undef
  }
  if $ensure == 'present' {
    exec { "tp::copy_file ${title}":
      command => "cp ${source} ${path}",
      path    => $facts['path'],
      creates => $exec_creates,
      unless  => $exec_unless,
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
        subscribe   => Exec["tp::copy_file ${title}"],
        refreshonly => true,
      }
    }
  } else {
    exec { "tp::copy_file ${title}":
      command => "rm -f ${path}",
      path    => $facts['path'],
      onlyif  => "test -f ${path}",
    }
  }
}
