# Tiny Puppet 

[![Build Status](https://travis-ci.org/example42/puppet-tp.png?branch=master)](https://travis-ci.org/example42/puppet-tp)
[![Coverage Status](https://coveralls.io/repos/example42/puppet-tp/badge.svg?branch=master&service=github)](https://coveralls.io/github/example42/puppet-tp?branch=master)

## Yet Another Puppet Abstraction Layer

[Tiny Puppet](http://www.tiny-puppet.com) is single Puppet module that manages virtually any application.

It can replace or integrate existing component application modules.


It features:

  - Quick, easy to use, standard, coherent, powerful interface to the managed resources

  - Out of the box and easily expandable support for most common Operating Systems

  - Modular data source design. Support for an easily growing [set of applications](https://github.com/example42/tinydata/tree/master/data).

  - Smooth coexistence with any existing Puppet modules setup: you decide what to manage

  - Application data stored in a configurable separated module ([tinydata](https://github.com/example42/tinydata) is the default source for applications data)

It is intended to be used in modules that operate at an higher abstraction layer (local site modules, profiles and so on) where we assemble and use different application modules to achieve the setup we need.

The expected user is a SysAdmin who knows how to configure his|her applications and wants a quick way to manage then without the need to "study" and include in the local modulepath a dedicated public module, or, even worse, write a new one from scratch.


## Important upgrade note for Version 1.x

Previous versions of tp (0.9.x) have this layout for defines::

    tp::install  # Works on Puppet 3 and 4 
    tp::install3 # Works on Puppet 3 and 4, clone of tp::install
    tp::install4 # Optimised for Puppet 4 (doesn't work on earlier versions)

Starting from version 1.x the naming is as follows:

    tp::install  # Optimised for Puppet 4 (doesn't work on earlier versions)
    tp::install3  # Works on Puppet 3 and 4 clone of tp::install from 0.x

If you use Puppet 4 you can use the default functions (without any suffix).

If you have a Puppet 3 or 2 environment you have to use defines with the 3 suffix (they work also on Puppet 4 but don't use any of the new language features).

We are sorry for the confusion, but we think that it's better to make this choice now, rather than mess more later or being forced to use an outdated Puppet version.


## Provided Resources

Tiny Puppet provides the following defines:

- ```tp::install```. It installs an application and starts its service, by default
- ```tp::conf```. It allows to manage configuration files
- ```tp::dir```. Manages the content of directories
- ```tp::stdmod```. Manages the installation of an application using StdMod compliant parameters
- ```tp::test```. Allows quick and easy (acceptance) testing of an application 
- ```tp::repo```. Manages extra repositories for the supported applications
- ```tp::puppi```. Puppi integration (Don't worry, fully optional) 
- ```tp::concat```. (WIP) Manages file fragments of a configuration file
- ```tp::netinstall```. (WIP) Installs from a remote url
- ```tp::instance```. (TODO) Manages an application instance
- ```tp::line```. (TODO?) Manages single lines in a configuration file
- ```tp::github```. (TODO?) Installs (anything?;) directly from GitHub source


## Prerequisites and limitations

Tiny Puppet is currently developed and mostly tested on Ruby 1.9.3, it's expected to work on more recent versions and **does not** work on Ruby 1.8.7.

This means that your Puppet Master should run on stock setups on these OS:
  - Ubuntu 14.04
  - Debian 7
  - RedHat 7
  - CentOS 7

Your clients may run on different Operating Systems and are actually supported in TP data, in fact, to run acceptance tests on other OS a compatible Ruby version is pre-installed in the provisioning of the relevant Vagrant boxes:
  - Ubuntu 12.04
  - Debian 6
  - CentOS 6

Tiny Puppet is expected to work on Puppet 3.x and Puppet 4.x.

**IMPORTANT NOTE**: Do not expect all the applications to flawlessly work out of the box for all the Operating Systems. Tiny Puppet manages applications that can be installed and configured using the underlying OS native packages and services, this might not be possible for all the cases.

Tiny Puppet requires these Puppet modules:

 - The [tinydata](https://github.com/example42/tinydata) module

 - Puppet Labs' [stdlib](https://github.com/puppetlabs/puppetlabs-stdlib) module.

If you use the relevant defines, other dependencies are needed:

  - Define ```tp::concat``` requires Puppet Labs' [concat](https://github.com/puppetlabs/puppetlabs-concat) module.

  - Define ```tp::dir``` , when used with the ```vcsrepo``` argument, requires Puppet Labs' [vcsrepo](https://github.com/puppetlabs/puppetlabs-vcsrepo) module.

  - Define ```tp::puppi``` requires Example42's [puppi](https://github.com/example42/puppi) module.


## Usage in manifests

### Essential usage patterns

Install an application with default settings (package installed, service started)

    tp::install { 'redis': }

Install an application specifying a custom dependency class (where, for example, you can add a custom package repository. Note however that for some applications and Operating System TP provides and manages automatically the upstream repository)

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

Install custom packages (with the ```settings_hash``` argument you can override any application specific setting)

    tp::install { 'redis':
      settings_hash => {
        'package_name'     => 'my_redis',
        'config_file_path' => '/opt/etc/redis',
      },
    }

Use the ```tp::stdmod``` define to manage an application using stdmod compliant parameters.

Note that ```tp::stdmod``` is alternative to ```tp::install``` (both of them manage packages and services) and may be complementary to ```tp::conf``` (you can configure files with both).

    tp::stdmod { 'redis':
      config_file_template => 'site/redis/redis.conf',
    }

To uninstall an application:

    tp::uninstall { 'redis': }


### Managing configurations

By default, configuration files managed by tp::conf automatically notify the service(s) and require the package(s) installed via tp::install. If you use tp::conf without a relevant tp::install define and have dependency cycle problems or references to non existing resources, you can disable these automatic relationships:

    tp::conf { 'bind':
      config_file_notify  => false,
      config_file_require => false,
    }

You can also set custom resource references to point to actual resources you declare in your manifests:

    tp::conf { 'bind':
      config_file_notify  => Service['bind9'],
      config_file_require => Package['bind9-server'],
    }

It's possible to manage files with different methods, for example directly providing its content:

    tp::conf { 'redis':
      content => 'my content is king',
    }

or providing a custom erb template (used as ```content => template($template)```):

    tp::conf { 'openssh::ssh_config':
      template    => 'site/openssh/ssh_config.erb',
    }

or using a custom epp template with Puppet code instead of Ruby (used as ```content => epp($epp)```):

    tp::conf { 'redis:
      epp   => 'site/redis/redis.conf.epp',
    }


also it's possible to provide the source to use, instead of managing it with the content argument:

    tp::conf { 'redis':
      source      => [ "puppet:///modules/site/redis/redis.conf-${hostname}" ,
                       'puppet:///modules/site/redis/redis.conf' ] ,
    }

Tp:conf has some conventions on the actual configuration file manages.

By default, if you just specify the application name, the file managed is the "main" configuration file of that application (in case this is not evident or may be questionable, check the data files for the actual value used).

    # This manages /etc/ssh/sshd_config
    tp::conf { 'openssh':
      [...]
    }

If you specify a file name after the application name in the title, separated by ```::```, that file is placed in the "base" configuration dir:

    # This manages /etc/ssh/ssh_config
    tp::conf { 'openssh::ssh_config':
      [...]
    }

If you explicitly set a path, that path is used and the title is ignored (be sure, anyway, to refer to a supported application and is not duplicated in your catalog): 

    # This manages /etc/ssh/ssh_config
    tp::conf { 'openssh::ssh_config':
      [...]
    }

If you explicitly set a path, that path is used and the title is ignored (be sure, anyway, to refer to a supported application and is not duplicated in your catalog): 

    # This manages /usr/local/bin/openssh_check
    tp::conf { 'openssh::ssh_check':
      path => '/usr/local/bin/openssh_check',
      [...]
    }

### Managing directories

Manage a whole configuration directory:

    tp::dir { 'redis':
      source      => 'puppet:///modules/site/redis/',
    }

Manage a specific directory type. Currently defined directories types are:
  - ```config``` : The application [main] configuration directory (Default value)
  - ```conf``` : A directory where you can place single configuration files (typically called ./conf.d )
  - ```data``` : Directory where application data resides
  - ```log``` : Dedicated directory for logs, if present

Note that some of these directory types might not be defined for every application.

    tp::dir { 'apache':
      base_dir => 'data',
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
      # base_dir is a tag that defines the type of directory for the specified application.
      # Default: config. Other possible dir types: 'data', 'log', 'confd', 'lib'
      # or any other name defined in the application data with a format like: ${base_dir}_dir_path
      base_dir    => 'data' 
      source      => 'https://git.example.42/apps/my_app/',
      vcsrepo     => 'git',
    }


### Managing repositories

Currently Tiny Puppet supports applications' installation only via the OS native packaging system. In order to cope with software which may not be provided by default on an OS, TP provides the ```tp::repo``` define that manages YUM and APT repositories for RedHat and Debian based Linux distributions.

The data about a repository is managed as all the other data of Tiny Puppet. Find [here](https://github.com/example42/tinydata/blob/master/data/elasticsearch/osfamily/Debian.yaml) an example for managing Apt repositories and [here](https://github.com/example42/tinydata/blob/master/data/elasticsearch/osfamily/RedHat.yaml) one for Yum ones.

Generally you don't have to use directly the ```tp::repo``` defined, as, when the repository data is present, it's automatically added from the ```tp::install``` one.

If, for whatever reason, you don't want to automatically manage a repository for an application, you can set to ```false``` the ```auto_repo``` parameter, and, eventually you can manage the repository in a custom dependency class:

    tp::install { 'elasticsearch':
      auto_repo        => false,
      dependency_class => '::site::elasticseach::repo', # Possible alternative class to manage the repo
    }


## Usage with Hiera

You may find useful the ```create_resources``` defines that are feed, in the main ```tp``` class by special ```hiera_hash``` lookups that map all the available ```tp``` defines to hiera keys in this format ```tp::<define>_hash```.

Although such approach is very powerful (and totally optional) we recommend not to abuse of it.

Tiny Puppet is intended to be used in modules like profiles, your data should map to parameters of such classes, but if you want to manage directly via Hiera some tp resources you have to include the main class:

    include tp

In the class are defined Hiera lookups (using hiera_hash so thy are recursive (and this may hurt a log when abusing) that expects parameters like the ones in the following sample in Yaml.

As an handy add-on, a ```create_resources``` is run also on the variables ```tp::packages```, ```tp::services```, ```tp::files``` to eventually manage the relevant Puppet resource types.

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

      tp::packages:
        wget:
          ensure: present
        zip:
          ensure: present
        curl:
          ensure: present

      tp::services:
        tuned:
          ensure: stopped
          enable: false
        NetworkManager:
          ensure: stopped
          enable: false


## Testing and playing with Tiny Puppet

You can experiment and play with Tiny Puppet using the [Tiny Puppet Playground](https://github.com/example42/tp-playground).

Acceptance tests are regularly done to verify tp support for different applications on different Operating Systems. They are in the [TP acceptance](https://github.com/example42/tp-acceptance) repo.

Check this [**Compatibility Matrix**](https://github.com/example42/tp-acceptance/blob/master/tests/app_summary.md) for a quick overview on how different applications are currently supported on different Operating Systems.


## Usage on the Command Line (TODO)

The following actions are going to be implemented as Puppet faces.

Their functionality is going to be similar to the one currently provided, via ```puppi``` by the ```tp::puppi``` define.


Install a specific application (TODO)

    puppet tp install redis


Retrieve contextual info about an application (TODO). For example the relevant network sockets, the output of diagnostic commands, 

    puppet tp info redis


Check if an application is running correctly (TODO)

    puppet tp check redis


Tail the log(s) of the specified application (TODO)

    puppet tp log redis


