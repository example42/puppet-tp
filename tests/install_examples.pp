
# Test 2 packages

notice('Test 2 packages')
tp::install { 'redis':
  packages  => {
    'redis' => { ensure => present } ,
    'redis2' => { ensure => present } ,
  },
  services  => {
    'redis' => { ensure => stopped , enable => true } ,
  },
}
