# Some basic tests

class site::test {

  tp::install { 'mailx': }
  tp::install { 'openssh': }
  tp::install { 'redis': }
  tp::install { 'samba': }

  tp::conf { 'redis':
    content => "# test default\n",
  }
  tp::conf { 'redis::test.conf':
    content => "# test test.conf\n",
  }

  tp::dir { 'redis':
    path        => '/opt/tp_self',
    source      => 'https://github.com/example.42/puppet-tp/',
    vcsrepo     => 'git',
  }

}
