tp::install { 'redis':

  packages  => {
    'redis' => { ensure => present } ,
    'redis2' => { ensure => present } ,
  }

}
