# Tiny Puppet

Note: This project is at early development stage.

Consider what follows as "ReadMe Driven Development"

Do not expect it to work out of the box, yet ;-)


## Usage in manifests

Install an application with default settings (package installed, service started)

    tp::install { 'redis': }

Install an application specifying a custom dependency class (where, for example, you can add a custom package rpository)

    tp::install { 'redis':
      dependency_class => 'site::redis::redis_dependency',
    }

Install custom packages:

    tp::install { 'redis':
      packages => {
        'redis' => { 'ensure' => 'present' }
        'redis-addons' => { 'ensure' => 'present' }
      },
    }

Install custom packages ( The packages parameter might be populated from a Hiera call ):

    tp::install { 'redis':
      packages => hiera('redis_packages'),
    }


Configure a file of an application providing a custom erb template:

    tp::conf { 'redis::redis.conf':
      template    => 'site/redis/redis.conf.erb',
    }


Configure a file of an application providing a custom epp template:

    tp::conf { 'redis::redis.conf':
      epp   => 'site/redis/redis.conf.epp',
    }


Provide a file via the fileserver:

    tp::conf { 'redis::redis.conf':
      source      => 'puppet:///modules/site/redis/redis.conf',
    }


Provide a whole configuration directory:

    tp::dir { 'redis':
      source      => 'puppet:///modules/site/redis/',
    }

Provide a whole configuration directory from a Git repository (it requires Puppet Labs' vcsrepo module):

    tp::dir { 'redis':
      source      => 'https://git.example.42/puppet/redis/conf/',
      vcsrepo     => 'git',
    }

Populate any custom directory from a Subversion repository (it requires Puppet Labs' vcsrepo module):

    tp::dir { 'logstash': # The title is irrilevant, when path argument is used 
      path        => '/opt/apps/my_app',
      source      => 'https://git.example.42/apps/my_app/',
      vcsrepo     => 'svn',
    }

Provide a data directory (the default DocumentRoot, for apache) from a Git repository (it requires Puppet Labs' vcsrepo module) (TODO):

    tp::dir { 'apache':
      # Dir_type is a tag that defines the type do directory for the specified application.
      # Default: config. Other possible dir types: 'data', 'log', 'confd', 'lib', available according to the application
      dir_type    => 'data' 
      source      => 'https://git.example.42/apps/my_app/',
      vcsrepo     => 'git',
    }


## Usage on the Command Line

 
Install a specific application (TODO)

    puppet tp install redis


Retrieve contextual info about an application (TODO). For example the relevant network sockets, the output of diagnostic commands, 

    puppet tp info redis


Check if an application is running correctly (TODO)

    puppet tp check redis

