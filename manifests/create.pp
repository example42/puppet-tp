#
#
# = Define: tp::create
#
# Create resources related to the named application
# Note: the title of tp::create is used just as a reference
#
define tp::create (

  $packages  = { } ,
  $services  = { } ,
  $files     = { } ,
  $users     = { } ,

  ) {

  # Resources
  if $packages {
    create_resources('package', $packages)
  }

  if $services {
    create_resources('service', $services)
  }

  if $files {
    create_resources('file', $files)
  }

  if $users {
    create_resources('user', $users)
  }

}
