# Some basic tests

class site::site {

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

  tp::dir { 'selt_test': # The title is irrilevant, when path argument is used 
    path        => '/opt/tp_self',
    source      => 'https://github.com/example.42/puppet-tp/',
    vcsrepo     => 'git',
  }

}
