# Redis tests
include tp

tp::conf { 'redis::red.conf':
  content => 'test',
}
tp::dir { 'redis':
  source => 'puppet:///modules/tp/files/test',
}
tp::install { 'redis': }

# Apache tp install 
tp::install { 'apache':
  files  => {
    '/tmp/apache.conf' => { content => 'test' } ,
  },
}
