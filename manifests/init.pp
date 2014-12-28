#
# Class: tp
#
# This class just provides hiera data entry points
# to create tp resources.
# If you don't use them, you don't need to include
# this class 
#
class tp () {

  # Hiera lookup to tp parameters
  $install_hash = hiera_hash('tp::install_hash' , {} )
  $conf_hash    = hiera_hash('tp::conf_hash' , {} )
  $dir_hash     = hiera_hash('tp::dir_hash' , {} )
  $concat_hash  = hiera_hash('tp::concat_hash' , {} )
  $stdmod_hash  = hiera_hash('tp::stdmod_hash' , {} )
  $puppi_hash   = hiera_hash('tp::puppi_hash' , {} )
  $repo_hash    = hiera_hash('tp::repo_hash' , {} )

  $packages     = hiera_hash('tp::packages' , {} )
  $services     = hiera_hash('tp::services' , {} )
  $files        = hiera_hash('tp::files' , {} )


  # TODO Be smarter here
  validate_hash($install_hash)
  validate_hash($conf_hash)
  validate_hash($dir_hash)
  validate_hash($concat_hash)
  validate_hash($stdmod_hash)
  validate_hash($puppi_hash)
  validate_hash($repo_hash)
  validate_hash($packages)
  validate_hash($services)
  validate_hash($files)

  if $install_hash != {} {
    create_resources('tp::install', $install_hash )
  }
  if $conf_hash != {} {
    create_resources('tp::conf', $conf_hash )
  }
  if $dir_hash != {} {
    create_resources('tp::dir', $dir_hash )
  }
  if $concat_hash != {} {
    create_resources('tp::concat', $concat_hash )
  }
  if $stdmod_hash != {} {
    create_resources('tp::stdmod', $stdmod_hash )
  }
  if $puppi_hash != {} {
    create_resources('tp::puppi', $puppi_hash )
  }
  if $repo_hash != {} {
    create_resources('tp::repo', $repo_hash )
  }
  if $packages != {} {
    create_resources('package', $packages )
  }
  if $services != {} {
    create_resources('service', $services )
  }
  if $files != {} {
    create_resources('file', $files )
  }

}
