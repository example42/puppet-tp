# Install and test 

tp::install { 'mailx': }
tp::install { 'openssh': }
tp::install { 'redis': }
tp::install { 'samba': }

tp::conf { 'test':
  content => test,
}
tp::conf { 'redis::test.conf':
  content => test,
}

    tp::dir { 'selt_test': # The title is irrilevant, when path argument is used 
      path        => '/opt/tp_self',
      source      => 'https://github.com/example.42/puppet-tp/',
      vcsrepo     => 'git',
    }
