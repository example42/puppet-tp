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

  $settings  = { } ,

  ) {

  $tp_packages=tp_lookup($title,'packages')
  $tp_services=tp_lookup($title,'services')
  $tp_files=tp_lookup($title,'files')

  $real_packages=merge($tp_packages,$packages)
  $real_services=merge($tp_services,$services)
  $real_files=merge($tp_files,$files)

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
