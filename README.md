# Tiny Puppet

Note: his project is at arly development stage
Consider what follows as "ReadMe Drivn Development"

## Usage in manifests

Install an application

    tp::install { 'redis': }


Configure a file of an application providing a custom a template:

    tp::conf { 'redis::redis.conf':
      template    => 'site/redis/redis.conf.erb',
    }


To configure it via the fileserver:

    tp::conf { 'redis::redis.conf':
      source      => 'puppet:///modules/site/redis/redis.conf',
    }


Configure a single line of a given file:

    tp::line { 'redis::redis.conf::port':
      value => '1234',
    }


Configure a fragment of a given file:

    tp::concat { 'redis::redis.conf':
      order   => '10',
      content => 'port 1234',
    }


Install an application and provide custom settings for internally used parameter:
    tp::install { 'redis':
      settings => {
        config_dir_path => '/opt/redis/conf',
        tcp_port        => '3242',
        pid_file_path   => '/opt/redis/run/redis.pid',
      },
    }


## Usage on the Command Line

Install a specific application

    puppet tp install redis


Retrieve contextual info about an application

    puppet tp info redis


Check if an application is running correctly

    puppet tp check redis


