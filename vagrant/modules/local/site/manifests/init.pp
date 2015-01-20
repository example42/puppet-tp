class site {

  include ::site::test
  include ::site::general

  if $role { 
    include "::site::role::${role}"
  }

}
