# Install and test 

    tp::install { 'openssh': }
    tp::conf { 'openssh::test':
      content => 'Test content',
    }
  
    package { 'git': }
    tp::dir { 'redis':
      path        => '/opt/tp_self',
      source      => 'https://github.com/example42/puppet-tp/',
      vcsrepo     => 'git',
      require     => Package['git'],
    }

# We just include our site module
# include site

