class site {

  include site::general

  if $role { 
    include site::role::$role
  }

}
