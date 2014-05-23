class { 'tp::redis':
  packages   =>  {
    'redis' => {
      ensure => absent,
    }
  },
  services   =>  { },
  files   =>  {
    '/tmp/redis.conf' => {
      content       => inline_template('<%= scope.to_hash.to_yaml %>'),
    }
  }
}
