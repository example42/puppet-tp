# Tiny Puppet

## Yet Another Puppet Abstraction Layer

Tiny Puppet is Puppet module that can replace or integrate other module ([List of supported applications](https://github.com/example42/puppet-tp/tree/master/data)).


It features:

  - Quick, easy to use, standard, coherent, powerful interface to the managed resources

  - Out of the box and easily expandable support for most common Operating Systems

  - Support of an quickly an easily growing [list of applications](https://github.com/example42/puppet-tp/tree/master/data).

  - Smooth coexistence with any existing Puppet modules setup: you decide what to manage

It is intended to be used in modules that operate at an higher abstraction layer (local site modules, profiles and so on) where we assemble and use different application modules to achieve the setup we need.


## Provided Resources

Tiny Puppet provides the following defines:

- ```tp::install```. It just installs an application and starts its service, by default
- ```tp::conf```. It allows to manage configuration files of an application with whatever method possible for files (as an ERB template, as an EPP template, via the fileserver, managing directly its content...)
- ```tp::dir```. Manages the content of a directory, either sourced from the fileserver or from repositories of most common VCS tools (Git, Mercurial, Subversion, Bazaar, CVS)
- ```tp::stdmod```. Manages the installation of an application using StdMod compliant parameters.
- ```tp::line```. (TODO) Manages single lines in a configuration file
- ```tp::concat```. (WIP) Manages file fragments of a configuration file
- ```tp::instance```. (TODO) Manages an application instance
- ```tp::puppi```. (WIP) Puppi integration (Don't worry, fully optional) 


## Usage in manifests

### Essential usage patterns

Install an application with default settings (package installed, service started)

    tp::install { 'redis': }

Install an application specifying a custom dependency class (where, for example, you can add a custom package repository)

    tp::install { 'lighttpd':
      dependency_class => 'site::lighttpd::repo',
    }

Configure the application main configuration file a custom erb template which uses data from a custom $options_hash:

    tp::conf { 'rsyslog':
      template     => 'site/rsyslog/rsyslog.conf.erb',
      options_hash => hiera('rsyslog::options_hash'),
    }

Populate any custom directory from a Git repository (it requires Puppet Labs' vcsrepo module):

    tp::dir { '/opt/apps/my_app': 
      source      => 'https://git.example.42/apps/my_app/',
      vcsrepo     => 'git',
    }


### Installation alternatives

Install custom packages (if the $packages hash is provided, is feed to create_resources('package',$packages))

    tp::install { 'redis':
      packages => {
        'redis'        => { 'ensure' => 'present' }
        'redis-addons' => { 'ensure' => 'present' }
      },
    }

Install custom packages ( The packages parameter might be populated from a Hiera call ):

    tp::install { 'redis':
      packages => hiera('redis_packages'),
    }

Use the tp::stdmod define to manage an application using stdmod compliant parameters.

Note that tp::stdmod is alternative to tp::install (both of them manage packages and services) and may be complementary to tp::conf.

    tp::stdmod { 'redis':
      config_file_template => 'site/redis/redis.conf',
    }


### Managing configurations

Configure an application main configuration file directly providing its content:

    tp::conf { 'redis':
      content => 'my content is king',
    }

Configure any configuration file of an application providing a custom erb template:

    tp::conf { 'openssh::ssh_config':
      template    => 'site/openssh/ssh_config.erb',
    }


Configure a file providing a custom epp template:

    tp::conf { 'redis:
      epp   => 'site/redis/redis.conf.epp',
    }


Provide a file via the fileserver:

    tp::conf { 'redis':
      source      => 'puppet:///modules/site/redis/redis.conf',
    }


### Managing directories

Manage a whole configuration directory:

    tp::dir { 'redis':
      source      => 'puppet:///modules/site/redis/',
    }

Manage a specific directory type. Currently defined directories types are:
  - 'config' : The application [main] configuration directory (Default value)
  - 'conf' : A directory where you can place single configuration files (typically called ./conf.d )
  - 'data' : Directory where application data resides
  - 'log' : Dedicated directory for logs, if present

Note that some of these directory types might not be defined for every application.

    tp::dir { 'apache':
      dir_type => 'data',
      source   => 'puppet:///modules/site/apache/default_site',
    }

Clone a whole configuration directory from a Git repository (it requires Puppet Labs' vcsrepo module):

    tp::dir { 'redis':
      source      => 'https://git.example.42/puppet/redis/conf/',
      vcsrepo     => 'git',
    }

Populate any custom directory from a Subversion repository (it requires Puppet Labs' vcsrepo module):

    tp::dir { 'my_app': # The title is irrilevant, when path argument is used 
      path        => '/opt/apps/my_app',
      source      => 'https://svn.example.42/apps/my_app/',
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


## Usage with Hiera

You may find useful the ```create_resources``` defines that are feed, in the main ```tp``` class by special ```hiera_hash``` lookups that map all the available ```tp``` defines to hiera keys in this format ```tp::<define>_hash```.

Although such approach is very powerful (and totally optional) we recommend not to abuse of it.

Tiny Puppet is intended to be used in modules like profiles, your data should map to parameters of such classes, but if you want to manage directly via Hiera some tp resources you have to include the main class:

    include tp

In the class are defined Hiera lookups (using hiera_hash so thy are recursive (and this may hurt a log when abusing) that expects parameters like the ones in the following sample in Yaml.

Not necessarily recommended, but useful to understand the usage basic patterns.

    ---
      tp::install_hash:
        memcache:
          ensure: present
        apache:
          ensure: present
        mysql
          ensure: present

      tp::conf_hash:
        apache:
          template: "site/apache/httpd.conf.erb"
        apache::mime.types:
          template: "site/apache/mime.types.erb"
        mysql:
          template: "site/mysql/my.cnf.erb"
          options_hash:
            

      tp::dir_hash:
        apache::certs:
          ensure: present
          path: "/etc/pki/ssl/"
          source: "puppet:///modules/site/certs/"
          recurse: true
          purge: true
        apache::courtesy_site:
          ensure: present
          path: "/var/www/courtesy_site"
          source: "https://git.site.com/www/courtesy_site"
          vcsrepo: git

      tp::puppi_hash:
        apache:
          ensure: present
        memcache:
          ensure: present
        php:
          ensure: present
        mysql:
          ensure: present


## Testing and playing with Tiny Puppet (WIP)

You can (try to) test Tiny Puppet on different Operating Systems with Vagrant:

    vagrant status

The default Vagrantfile uses the cachier plugin, you can install it with:

    vagrant plugin install vagrant-cachier

The manifest file used for Puppet provisioning is ```vagrant/manifests/site.pp```, you can play with Tiny Puppet there.

Do not expect everything to work seamlessly, this is a test environment to verify functionality and coverage on different Operating Systems. 


## Usage on the Command Line (TODO)

 
Install a specific application (TODO)

    puppet tp install redis


Retrieve contextual info about an application (TODO). For example the relevant network sockets, the output of diagnostic commands, 

    puppet tp info redis


Check if an application is running correctly (TODO)

    puppet tp check redis


Tail the log(s) of the specified application (TODO)

    puppet tp log redis


