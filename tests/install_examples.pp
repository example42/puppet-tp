
# Test 2 packages

notice('Test 2 packages')
tp::install { 'redis':
  packages  => {
    'redis' => { ensure => present } ,
    'redis2' => { ensure => present } ,
  },
  services  => {
    'redis' => { ensure => stopped , enable => false } ,
  },
  files  => {
    '/tmp/redis.conf' => { content => 'test' } ,
  },
}

notice('Config change')
tp::install { 'apache':
  files  => {
    '/tmp/apache.conf' => { content => 'test' } ,
  },
}
