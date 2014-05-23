#
# = Define: tp
#
# This class installs and manages tp
#
#
# == Parameters
#
define tp::install (

  $packages  = { } ,
  $services  = { } ,
  $files     = { } ,

  $configs   = { } ,

  ) {

  $real_packages=tp_lookup($title,'packages')
  $real_services=tp_lookup($title,'services')
  $real_files=tp_lookup($title,'files')

  if $real_packages {
    create_resources('package', $real_packages)
  }

  if $real_services {
    create_resources('service', $real_services)
  }

  if $real_files {
    create_resources('file', $real_files)
  }

}
