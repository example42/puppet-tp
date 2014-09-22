tp::install { 'redis': }
tp::install { 'openssh': }

tp::install { 'apache':
  files  => {
    '/tmp/apache.conf' => { content => 'test' } ,
  },
}

tp::conf { 'apache::test':
  content => test,
tp::conf { 'openssh::test':
  content => test,
}
tp::conf { 'apache::test':
  content => test,
}
