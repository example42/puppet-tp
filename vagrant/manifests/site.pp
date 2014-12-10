# Install and test 

    
    tp::install { 'openssh': }
    tp::install { 'redis': }
    tp::install { 'samba': }
  
    tp::conf { 'redis':
      content => "# test default\n",
    }
    tp::conf { 'redis::test.conf':
      content => "# test test.conf\n",
    }
  
    package { 'git': }
    tp::dir { 'redis':
      path        => '/opt/tp_self',
      source      => 'https://github.com/example42/puppet-tp/',
      vcsrepo     => 'git',
    }

# We just include our site module
# include site

