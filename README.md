# Tiny Puppet 


[![Build Status](https://travis-ci.org/example42/puppet-tp.png?branch=master)](https://travis-ci.org/example42/puppet-tp)
[![Coverage Status](https://coveralls.io/repos/example42/puppet-tp/badge.svg?branch=master&service=github)](https://coveralls.io/github/example42/puppet-tp?branch=master)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/6fad76feb4a043289399cd9a91ccb1de)](https://www.codacy.com/app/example42/puppet-tp?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=example42/puppet-tp&amp;utm_campaign=Badge_Grade)

#### Table of Contents

1. [Module description - What Tiny Puppet does?](#module-description)
    * [Features](#features)
    * [Use cases](#use-cases)
2. [Setup](#setup)
    * [What tp affects](#what-tp-affects)
    * [Getting started with tp](#getting-started-with-tp)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Usage in Puppet code](#usage-in-puppet-code)
    * [Installation options](#installation-options)
    * [Installation alternatives](#installation-alternatives)
    * [Managing configurations](#managing-configurations)
    * [Managing directories](#managing-directories)
    * [Managing repositories](#managing-repositories)
    * [Usage on the command line](#usage-on-the-command-line)
4. [Reference](#reference)
    * [Classes](#classes)
    * [Defined Types](#defined-types)
    * [Types](#types)
    * [Functions](#functions)
    * [Tasks](#tasks)
5. [Prerequisites and limitations](#prerequisites-and-limitations)
6. [Tests](#tests)



## Module description

The tp (short for Tiny Puppet) module allows you to manage any application on any (Linux flavours, Solaris, Darwin, Windows) Operating System.

It provides Puppet defined types to install packages and manage services (`tp::install`), eventually handling relevant repos (`tp::repo`) and then manage their configuration files (`tp::conf`) and directories (`tp::dir`).

### Features

* Quick, easy to use, standard, coherent, powerful interface to applications installation and their config files management.
* Out of the box and easily expandable support for most common Operating Systems
* Modular data source design. Support for an easily growing [set of applications](https://github.com/example42/tinydata/tree/master/data).
* Smooth coexistence with any existing Puppet modules setup: you decide what to manage
* Application data stored in a configurable separated module ([tinydata](https://github.com/example42/tinydata) is the default source for applications data)
* Optional shell command (`tp`) which can be used to install, test, query for logs any tp managed application.

### Use cases

Tiny Puppet is intended to be used in profiles, as replacement for dedicated componenent modules, or in the same modules, to ease the management of the provided files and packages.

The expected users are both experienced sysadmins who know exactly how to configure their applications and absolute beginners who want to simply install an application, without knowing how it's package is called on the underlying system or how to install its repositories or dependencies.

To see real world usage of tp defines give a look to the [profiles](https://github.com/example42/puppet-psick/tree/master/manifests) in the psick module. 


## Setup

### What tp affects

* any application package which is possible to install with the OS native package manager
* eventually application specific package repository files or release packages (if relevant tinydata is present)
* configuration files of any application (for which there's tinydata). Content is up to the user.
* full directories, whose source can also be a scm repository

### Getting started with tp

Tiny Puppet is typically used in profiles, custom classes where we place the code we need to manage applications in the way we need.

This is a simple case, where the content of a configuration file is based on a template with custom values.

    class profile::openssh (
      String $template = 'profile/openssh/sshd_config.erb',
      Hash $options    = {},
    ) {

      tp::install { 'openssh': }
      tp::conf { 'openssh':
        template     => $template,
        options_hash => $options,
      }
    }


## Usage


### Usage in Puppet code

Install an application with default settings (package installed, service started)

    tp::install { 'redis': }

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


### Installation options

Install custom packages (with the ```settings_hash``` argument you can override any application specific setting)

    tp::install { 'redis':
      settings_hash => {
        'package_name'     => 'my_redis',
        'config_file_path' => '/opt/etc/redis',
      },
    }

Some options are available to manage tp::install automation:

    tp::install { 'virtualbox':
      auto_repo          => true,  # This is the default, settings, if defined in tinydata, it installs the relevant package repository
      auto_conf          => true,  # True by default. If defined in tinydata a default configuration is provided
      auto_prerequisites => false, # False by default. If true eventual package or tp::install dependencies are installed
    }

Other options are available to manage integrations:

    tp::install { 'rabbitmq':
      cli_enable    => true,  # Default value. Installs the tp command on the system and provides the data about the defined application.
      puppi_enable  => false, # Default value. Installs puppi and enables puppet integration
      test_template => undef, # Default value. If provided, the provided erb template is used as script to test the application (instead of default tests)
      options_hash  => {}     # An optional hash where to set variable to use in the test_template.
    }

To uninstall an application, there are two alternatives:

    tp::uninstall { 'redis': }
    tp::install { 'redis': ensure => absent }


### Installation alternatives

To manage packages installations and configuration files there's also the ```tp::stdmod``` define to manage an application using stdmod compliant parameters.

Note that ```tp::stdmod``` is alternative to ```tp::install``` (both of them manage packages and services) and may be complementary to ```tp::conf``` (you can configure files with both).

    tp::stdmod { 'redis':
      config_file_template => 'site/redis/redis.conf',
    }

If you wonder what's better, use ```tp::install``` + ```tp::conf``` rather than ```tp::stdmod```.


### Managing configurations

By default, configuration files managed by tp::conf automatically notify the service(s) and require the package(s) installed via tp::install. If you use tp::conf without a relevant tp::install define and have dependency cycle problems or references to non existing resources, you can disable these automatic relationships:

    tp::conf { 'bind':
      config_file_notify  => false,
      config_file_require => false,
    }

You can also set custom resource references to point to actual resources you declare in your manifests:

    tp::conf { 'bind':
      config_file_notify  => 'Service[bind9]',
      config_file_require => 'Package[bind9-server]',
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

#### tp::conf file paths conventions

Tp:conf has some conventions on the actual configuration file manages.

By default, if you just specify the application name, the file managed is the "main" configuration file of that application (in case this is not evident or may be questionable, check the ```config_file_path``` value in the tinydata files for the used application).

    # This manages /etc/ssh/sshd_config
    tp::conf { 'openssh':
      [...]
    }

If you specify a file name after the application name in the title, separated by ```::```, and you don't specify any alternative ```base_file```, then that file is placed in the "base" configuration dir (```config_dir_path``` in tinydata):

    # This manages /etc/ssh/ssh_config
    tp::conf { 'openssh::ssh_config':
      [...]
    }

If you specify the parameter ```base_file``` then the path is the one of the specified base_file and the title does not provide any information about the managed file path (it still needs the relevant app in the first part, before ::, and it needs to be unique across the catalog). For example if  ```base_file => 'init'``` the path used is the value of the ```init_file_path``` key in the relevant tinydata.

    # This manages /etc/default/puppetserver on Debian or /etc/sysconfig/puppetserver on RedHat
    tp::conf { 'puppetserver::init':
      base_file => 'init',
      [...]
    }

If you explicitly set a ```path```, that path is used and the title is ignored (be sure, anyway, to refer to a supported application and is not duplicated in your catalog):

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

Currently Tiny Puppet supports applications' installation only via the OS native packaging system or Chocolatey on Windows and HomeBrew on MacOS. In order to cope with software which may not be provided by default on an OS, TP provides the ```tp::repo``` define that manages YUM and APT repositories for RedHat and Debian based Linux distributions.

The data about a repository is managed as all the other data of Tiny Puppet. Find [here](https://github.com/example42/tinydata/blob/master/data/elasticsearch/osfamily/Debian.yaml) an example for managing Apt repositories and [here](https://github.com/example42/tinydata/blob/master/data/elasticsearch/osfamily/RedHat.yaml) one for Yum ones.

Generally you don't have to use directly the ```tp::repo``` define, as, when the repository data is present, it's automatically added from the ```tp::install``` one.

When it's present the relevant data for an application, it's possible to install it using different alternative repos. For example you can use:

    tp::install { 'mongodb':
      repo => 'mongodb-org-3.2',
    }

to install MongoDB using packages from the 3.2 upstream repo, instead of the default OS ones.

In some cases, where for the given application name there are no packages, the following commands have exactly the same effect:

    tp::install { 'epel': }  # Installs Epel repository on RedHat derivatives. Does nothing on other OS.
    tp::repo { 'epel': }     # Same effect of tp::install since no package is actually installed

If, for whatever reason, you don't want to automatically manage a repository for an application, you can set to ```false``` the ```auto_repo``` parameter, and, eventually you can manage the repository in a custom dependency class:

    tp::install { 'elasticsearch':
      auto_repo        => false,
    }

### Using alternative data sources

By default Tiny Puppet uses the [tinydata](https://github.com/example42/tinydata) module to retrieve data for different applications, but it's possible to use a custom one:

    tp::install { 'apache':
      data_module => 'my_data', # Default: tinydata
    }

Reproduce the structure of tinydata in your data module to make it work with tp.

If you want to use your own data module for all your applications, you might prefer to set the following resource defaults in your main manifest (```manifest/site.pp```, typically):

    Tp::Install {
      data_module  => 'my_data',
    }
    Tp::Conf {
      data_module  => 'my_data',
    }
    Tp::Dir {
      data_module  => 'my_data',
    }

Starting from version 2.3.0 (with tinydata version > 0.3.0) tp can even install applications for which there's no tinydata defined. In this case just the omonimous package is (tried to be) installed and a warning about missing tinydata is shown.


### Usage on the command line

Tiny Puppet adds the tp command to Puppet. Just have it in your modulepath and install the tp command with:

    puppet tp setup

With the tp command you can install on the local OS the given application, taking care of naming differences, additional repos or prerequisites.

    tp install <application>
    tp uninstall <application>

    tp test # Test all the applications installed by tp
    tp test <application> # Test the specified application

    tp log # Tail all the logs of all the applications installed by tp
    tp log <application> # Tail the log of the specified application

Each of these commands can be inkoed also via the tp puppet face:

    puppet tp <command> <arguments>



## Reference

The tp modules provides the following resources.

### Classes

* ```tp``` Offers antry points for data driven management of tp resources, and the possibility to install the tp command

### Defined types

- ```tp::install```. It installs an application and starts its service, by default
- ```tp::conf```. It allows to manage configuration files
- ```tp::dir```. Manages the content of directories
- ```tp::stdmod```. Manages the installation of an application using StdMod compliant parameters
- ```tp::test```. Allows quick and easy (acceptance) testing of an application 
- ```tp::repo```. Manages extra repositories for the supported applications
- ```tp::puppi```. Puppi integration (Don't worry, fully optional) 

### Types

* [tp-settings], validates all the possible setting for tinydata

### Functions

* [tp::content], manages content for files based on supplied (erb) template, epp, and content
* [tp::ensure2bool], converts ensure values to boolean
* [tp::ensure2dir], converts ensure values to esnure values to be used for directories
* [tp::install], wrapper around the tp::install define, it tries to avoid eventual duplicated resources issues
* [tp::is_something], returna true if input of any type exists and is not empty

### Tasks

* [`tp::test`], runs a tp test command on a system to check status of [tp] installed applications

Refer to in code documentation for full reference.

Check [Puppetmodule.info](http://www.puppetmodule.info/modules/example42-tp/) for online version.


## Prerequisites and limitations

Current version of Tiny Puppet is compatible with Puppet 4.4 or later and PE 2016.1.1 or later.

To use it on Puppet 3 you have to use tp version 1.x with the 3.x compatible defines (with the ```3``` suffix).

If tp doesn't correctly install a specific application on the OS you want, please **TELL US**.
It's very easy and quick to add new apps or support for new OS in tinydata.

Currently most of the applications are supported on RedHat and Debian derivatives Linux distributions, but as long as you provide a valid installable package name, tp can install **any** application given in the title, even if there's no specific Tinydata for it..

Tiny Puppet requires these Puppet modules:

  - The [tinydata](https://github.com/example42/tinydata) module

  - Puppet Labs' [stdlib](https://github.com/puppetlabs/puppetlabs-stdlib) module.

In order to work on some OS you need some additional modules and software:

  - On **Windows** you need [Chocolatey](https://chocolatey.org/) and [puppetlabs-chocolatey](https://forge.puppet.com/puppetlabs/chocolatey) module with chocolatey package provider.
  
  - On **Mac OS** you need [Home Brew](https://brew.io/) and [thekevjames-homebrew](https://forge.puppet.com/thekevjames/homebrew) or equivalent module with homebrew package provider.

If you use the relevant defines, other dependencies are needed:

  - Define ```tp::concat``` requires [puppetlabs-concat](https://github.com/puppetlabs/puppetlabs-concat) module.

  - Define ```tp::dir``` , when used with the ```vcsrepo``` argument, requires [puppetlabs-vcsrepo](https://github.com/puppetlabs/puppetlabs-vcsrepo) module.

  - Define ```tp::puppi``` requires [example42-puppi](https://github.com/example42/puppi) module.


## Tests

You can experiment and play with Tiny Puppet and see a lot of use examples on [Example42's PSICK control-repo](https://github.com/example42/psick).

Acceptance tests are done to verify tp support for different applications on different Operating Systems. They are in the [TP acceptance](https://github.com/example42/tp-acceptance) repo.

