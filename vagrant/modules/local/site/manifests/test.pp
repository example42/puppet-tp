# Some basic tests

class site::test {

  tp::install { 'redis': }

  tp::conf { 'redis::test':
    content => "# test default\n",
  }
  tp::conf { 'redis::test.conf':
    content => "# test test.conf\n",
  }

  tp::dir { 'test':
    path        => '/opt/tp_self',
    source      => 'https://github.com/example42/puppet-tp/',
    vcsrepo     => 'git',
  }

}
