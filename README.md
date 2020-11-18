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
3. [Usage in Puppet code](#usage-in-puppet-code)
    * [Common uses](#common-uses)
    * [Installing packages - tp::install](#Installing-packages---tp::install)
    * [Installation alternatives - tp::stdmod [DEPRECATED]](#Installation-alternatives---tp::stdmod-DEPRECATED)
    * [Managing configurations - tp::conf](#Managing-configurations---tp::conf)
      * [tp::conf file paths conventions](#tp::conf-file-paths-conventions)
    * [Managing directories - tp::dir](#managing-directories---tp::dir)
    * [Managing repositories - tp::repo](#managing-repositories---tp::repo)
    * [Configuring tp resources via Hiera](#configuring-tp-resources-via-hiera)
4. [Updating tiny data and using alternative data sources](#Updating-tiny-data-and-using-alternative-data-sources)
5. [Usage on the command line](#usage-on-the-command-line)
6. [Reference](#reference)
    * [Classes](#classes)
    * [Defined Types](#defined-types)
    * [Types](#types)
    * [Functions](#functions)
    * [Tasks](#tasks)
7. [Prerequisites and limitations](#prerequisites-and-limitations)
8. [Additional info](#additional-info)

## Module description

Example42's tp (short for Tiny Puppet) module can manage **any application** on **any Operating System** (Linux flavours, Solaris, MacOS, Windows).

It provides Puppet user defined types to:

- Install applications' packages and manage their services (`tp::install`)
- Handle eventual relevant repos, allowing to choose between native distro repos or the ones from upstream developer (`tp::repo`)
- Manage applications configuration files (`tp::conf`)
- Manage whole directories (`tp::dir`), also from a SCM source.

### Features

The main features of tp module are:

- Quick, easy to use, standard, coherent, powerful interface to applications installation and their config files management.
- Out of the box and easily expandable support for most common Operating Systems
- Modular data source design. Support for an easily growing [set of applications](https://github.com/example42/tinydata/tree/master/data).
- Smooth coexistence with any existing Puppet modules setup: it's up to the user to decide when to use tp and when to use a dedicated module
- Application data stored in a configurable separated module ([tinydata](https://github.com/example42/tinydata) is the default source for applications data)
- Optional CLI command (`tp`) which can be used to install, test, query for logs any tp managed application.

### Use cases

Tiny Puppet can be considered a complement or a replacement of standard component modules.

It's particularly useful when there are to manage packages, services and configuration files, for more complex and application specific resources a dedicated module is probably preferable.

It can be used in the following cases:

- In local **profiles**, as alternative to custom resources or dedicated modules, to ease the management of the relevant applications
- Directly via Hiera, specifying in data hashes of tp resources to apply. Check [Configuring tp resources via Hiera](#configuring-tp-resources-via-hiera) section for details.
- Even in **component modules** to leverage on the abstraction on Operating Systems to easily handle package and service names, configuration files paths and upstream repositories

The intended users can be any of the following:

- **experienced sysadmins** who know exactly how to configure their applications without digging into dedicated modules documentation or adapting to their logic
- **absolute Puppet beginners** who struggle to use and integrate common modules and need a quick and fast way to install and configure applications
- **Puppet experts** who leverage on tp resources who want to optimise and limit the amount of resources on nodes catalogs and the number of external modules to use

To see real world usage of tp defines give a look to:

- the [profiles](https://github.com/example42/puppet-psick/tree/master/manifests) in the psick module where tp or tp_profiles are used widely
- usage samples in [hieradata](https://github.com/example42/psick-hieradata/search?q=%27tp%3A%3A%27).
- the [tp_profile](https://github.com/example42/puppet-tp_profile) module which contains standard classes for different applications which rely entirely on tp resources


## Setup

TP can be installed as any other module, with different To install tp module you can:

- From the forge, via the puppet module command on the the CLI:

        puppet module install example42-tp

- From the forge, adding to Puppetfile and entry like

        mod 'example42-tp', 'latest' # For latest version
        mod 'example42-tp', '3.0.0'  # For a specific version (recommended)

- From the forge, initializing a new Bolt project with this module:

        bolt project init --modules example42-tp

- From GitHub repository, cloning the module in your local $modulepath

        git clone https://github.com/example42/puppet-tp.git tp

Once tp module is added to the modulepath the (optional) tp command can be installed to a node in the following ways:

- Classifing the tp class for the node in Puppet manifests (or via other classification approaches):

        include tp

- Directly for the command line on the target node, as root:

        puppet tp setup

### What tp affects

* any application package which is possible to install with the OS native package manager
* eventually application specific package repository files or release packages (if relevant tinydata is present)
* configuration files of any application (for which there's tinydata). Content is up to the user.
* full directories, whose source can also be a scm repository

### Getting started with tp

Here follows an example of tp resources used inside a custom profile where the content of a configuration file is based on a template with custom values.

    class profile::openssh (
      String $server_template = 'profile/openssh/sshd_config.erb',
      String $client_template = 'profile/openssh/ssh_config.erb',
      Hash $options    = {},
    ) {

      # OpenSSH installation
      tp::install { 'openssh': }

      # Configuration of sshd_config server configuration file (main config file)
      tp::conf { 'openssh':
        template     => $server_template,
        options_hash => $options,
      }

      # Configuration of ssh_config client configuration file
      tp::conf { 'openssh::ssh_config':
        template     => $client_template,
        options_hash => $options,
      }
    }

The above class, once included, will:

- Install the openssh package (name of the package adapted to the underlying OS)
- Manage the /etc/ssh/sshd_config and /etc/ssh/ssh_config files (eventually on different paths, according to the OS)
- Start the service openssh (name adapted to OS) taking care of dependencies and service restarts on files changes (restart behaviour can be customised)

In the defined templates key-values set in the $options hash can be accessed via <%= @options['key_name'] %> (example for an erb template), so, with hieradata as follows:

    profile::openssh::options:
      StrictHostKeyChecking: yes

we can have in the used templates lines as follows:

    StrictHostKeyChecking: <%= @options['StrictHostKeyChecking'] %>

## Usage in Puppet code

The user defined types (or defines, or user defines) provided by tp module can be used in Puppet manifests to manage installation and configuration of applications. They can be very simple and essential ( tp::<define> { 'Application name': }) but provide several paramters which can be used to customise and fine tune the managed resources as needed.

### Common uses

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


### Installing packages - tp::install

Some parameters are available to manage tp::install automation:

- **upstream_repo** Default: true. When true, uses the repo from the upstream developer, if defined in tinydata
- **auto_conf** Default: true. If true and tinydata relevant is present a default configuration is provided (this could happen just when some basic configuration is needed to actually activate the service)
- **auto_prereq**  Default: false. If true eventual package, tp::install or other dependencies dependencies are installed automatically. To minimize duplicated resources risk this is false by default, but might be required to setup specific applications correctly.

    tp::install { 'consul':
      upstream_repo => true,
      auto_conf     => true,
      auto_prereq   => false,
    }

Other parameters are available to manage integrations:

- **cli_enable** Default: true. Installs the tp command on the system and provides the data about the application used by ```tp log``` and ```tp test``` commands.
- **puppi_enable** Default: false. Installs [Puppi](https://github.com/example42/puppi) and enables puppi integration
- **test_enable** Default: false. If to enable automatic testing of the managed application.
- **test_template** Default: undef. If provided, the provided erb template is used as script to test the application (instead of default tests)
- **options_hash** Default: {}. An optional hash where to set variable to use in test_template.

Some specific params are to handle repos:

- **repo** Default: undef. Name of the upstrem_repo to use. This allows, if tinydata is present, to customise the repo to use (for example to manage installation of specific versions of an application)
- **repo_exec_environment** Default []. An array passed to the environment argument of exec types used inside tp::repo define, declared within tp::install when a repo is configured. Can be useful when trying to use tp::repo from behind a proxy

These parameters allow to skip management of packages or services:
- **manage_package** Default: true. When false, tp::install doesn't handle packages, even when there's a package_name defined in tinydata.
- **manage_service** Default: true. When false, tp::install doesn't handle services, even when there's a service_name defined in tinydata.

Some parameters allow to configure tp::conf and tp::dir resources directly from tp::install (inheriting the saem settings and options):

- **conf_hash**. Default: { }. An hash of tp::conf resources to create. These resources will refer to the same application specified in the tp::install $title and inherits the settings ensure, settings_hash, options_hash and data_module
- **dir_hash**. Default: { }. An hash of tp::dir resources to create, as for the conf one.

Parameters are also available to customise the tiny data settings which affects package and service names, repos settings, file paths and so on. The params are common to all the tp defines, check [Updating tiny data and using alternative data sources](#Updating-tiny-data-and-using-alternative-data-sources) section for details.

- **settings_hash** Default: {}. An optional hash which can be used to override tinydata settings 
- **data_module** Default: 'tinydata'. The name of the module to use to get tp data for the managed application

An example with a custom test for the rabbitmq service:

    tp::install { 'rabbitmq':
      cli_enable    => true,
      test_enable   => true,
      test_template => 'profile/rabbitmb/tp_test.erb',
      options_hash  => { 'server' => "rabbitmq.${::domain}" }
    }

It's possible to specify the version of the package to install (the provided version must be available in the configured repos):

    tp::install { 'postfix':
      ensure => '2.10.1-9',
    }

To uninstall an application, there are two alternatives:

    tp::uninstall { 'redis': }
    tp::install { 'redis': ensure => absent }


### Installation alternatives - tp::stdmod

To manage packages installations and configuration files there's also the ```tp::stdmod``` define to manage an application using [stdmod](https://github.com/stdmod) compliant parameters.

Note that ```tp::stdmod``` is alternative to ```tp::install``` (both of them manage packages and services) and may be complementary to ```tp::conf``` (you can configure files with both).

    tp::stdmod { 'redis':
      config_file_template => 'site/redis/redis.conf',
    }

If you wonder what's better, use ```tp::install``` + ```tp::conf``` rather than ```tp::stdmod```.


### Managing configurations - tp::conf

The tp::conf define is basically a wrapper over a file resource which makes it easy and fast to manage configuration files for an application, handling the correct permissions, paths and owners for the underlying OS. Be aware anyway that the contents of the managed files are entirely up to you: Tiny Puppet does not have any awareness of the configuration options available for the managed applications.

If as title is passed just the name of the application, Tiny Puppet tries to configure its *main configuration file*. There are various ways to manage other configuration files related to the application as detailed in the section [tp::conf file paths conventions](#tp::conf-file-paths-conventions).

It's possible to manage files with different methods, for example directly providing its content:

    tp::conf { 'redis':
      content => 'my content is king',
    }

or providing a custom erb template (used as ```content => template($template)```) with custom options:

    tp::conf { 'openssh::ssh_config':
      template     => 'profile/openssh/ssh_config.erb',
      options_hash => {
        UsePAM        => 'yes',
        X11Forwarding => 'no',
      } 
    }

In the profile/templates/openssh/ssh_config.erb template you will have the contents you want and use the above options with something like (note you can use both the @options and the @options_hash variable):

    [...]
    UsePAM <%= @options['UsePAM'] %>
    X11Forwarding <%= @options['X11Forwarding'] %>
    [...]

Alternatively a custom epp template with Puppet code instead of Ruby (used as ```content => epp($epp)```):

    tp::conf { 'redis:
      epp   => 'site/redis/redis.conf.epp',
    }

also it's possible to provide the source to use, instead of managing it with the content argument:

    tp::conf { 'redis':
      source      => [ "puppet:///modules/site/redis/redis.conf-${hostname}" ,
                       'puppet:///modules/site/redis/redis.conf' ] ,
    }

For applications for which it exists the setting 'config_file_format' you can just pass the hash of options_hash of settings to configure and tp::conf creates a valid configuration file for the application:

    tp::conf { 'filebeat':
      options_hash => {
        filebeat.modules => ['module: system']
        syslog => {
          enabled   => true,
          var.paths => ["/var/log/syslog*","/var/log/messages"],
        }
      }
    }

This example makes much more sense if based on Hiera data (see [Configuring tp resources via Hiera](#configuring-tp-resources-via-hiera) section for details):

    tp::conf_hash:
      filebeat:
        options_hash:
          filebeat.modules:
          - module: system
          syslog:
            enabled: true
            var.paths:
              - "/var/log/syslog*"
              - "/var/log/messages"

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

Tiny Puppet even validates the syntax of the managed configuration files before applying them, if the setting 'validate_cmd' is present in Tiny Data. To disable this validation, which prevents Puppet from changing a file if its syntax is wrong, set **validate_syntax** parameter to false.

#### tp::conf file paths conventions

Tp:conf has some conventions on the actual configuration file managed.

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

### Managing directories - tp::dir

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

Provide a data directory (the default DocumentRoot, for apache) from a Git repository (it requires Puppet Labs' vcsrepo module) :

    tp::dir { 'apache':
      # base_dir is a tag that defines the type of directory for the specified application.
      # Default: config. Other possible dir types: 'data', 'log', 'confd', 'lib'
      # or any other name defined in the application data with a format like: ${base_dir}_dir_path
      base_dir    => 'data' 
      source      => 'https://git.example.42/apps/my_app/',
      vcsrepo     => 'git',
    }

Continuous deployment the tiny way: automatically deploy the latest version of an app from a git repo whenever Puppet runs:

    tp::dir { 'my_app':
      ensure  => latest,
      path    => '/opt/apps/my_app',
      source  => 'https://git.example.42/apps/my_app/',
      vcsrepo => 'git',
    }

### Managing repositories - tp::repo

Currently Tiny Puppet supports applications' installation only via the OS native packaging system or Chocolatey on Windows and HomeBrew on MacOS. In order to cope with software which may not be provided by default on an OS, TP provides the ```tp::repo``` define that manages YUM and APT repositories for RedHat and Debian based Linux distributions.

The data about a repository is managed as all the other data of Tiny Puppet. Find [here](https://github.com/example42/tinydata/blob/master/data/elasticsearch/osfamily/Debian.yaml) an example for managing Apt repositories and [here](https://github.com/example42/tinydata/blob/master/data/elasticsearch/osfamily/RedHat.yaml) one for Yum ones.

Generally you don't have to use directly the ```tp::repo``` define, as, when the repository data is present, it's automatically added from the ```tp::install``` one.

When it's present the relevant data for an application, it's possible to install it using different alternative repos. For example you can use this synatx to install the repo for the Elastic stack version 6.x:

    tp::install { 'elastic_repo':
      repo => '6.x',
    }

In some cases, where for the given application name there are no packages, the following commands have exactly the same effect:

    tp::install { 'epel': }  # Installs Epel repository on RedHat derivatives. Does nothing on other OS.
    tp::repo { 'epel': }     # Same effect of tp::install since no package is actually installed

If, for whatever reason, you don't want to automatically manage a repository for an application, you can set to ```false``` the ```auto_repo``` parameter, and, eventually you can manage the repository in a custom dependency class:

    tp::install { 'elasticsearch':
      auto_repo => false,
    }

Tinydata has information about various useful repos, both general or application/vendor specific. They are a tp::install away, all the following ones add repos for RedHat systems and derivatives:

- ```tp::install {'epel': }```. Configures [Epel](https://fedoraproject.org/wiki/EPEL){:target="_blank"} repo on RedHat and derivatives
- ```tp::install {'rpmfusion-free': }``` - ```tp::install {'rpmfusion-nonfree': }```. Configure [RPM Fusion](https://rpmfusion.org/){:target="_blank"} free and nonfree repo
- ```tp::install {'ius': }```. Configures [IUS](https://ius.io/){:target="_blank"} repo
- ```tp::install {'remi': }```. Configures [Remi Repository](https://rpms.remirepo.net/){:target="_blank"}
- ```tp::install {'elrepo': }```. Configures [ELRepo](http://elrepo.org/tiki/){:target="_blank"}
- ```tp::install {'nux': }```. Configures [Nux DexTop](http://li.nux.ro/repos.html){:target="_blank"} repo
- ```tp::install {'ulyaoth': }```. Configures [Ulyaoth](https://community.ulyaoth.com/resources/categories/repository.1/){:target="_blank"} repo

There is also Tiny Data for some vendors repos, sometimes they are directly in the relevant application data, somethins in a dedicated name space:

- ```tp::install {'elastic_repo': }```. Configures [ELastic](https://elastic.com){:target="_blank"} repo on RedHat and Debian derivatives
- ```tp::install {'hashicorp_repo': }```. Configures [Hashicorp](https://hashicorp.com){:target="_blank"} repo on RedHat, Amazon, Fedora and Debian derivatives

### Configuring tp resources via Hiera

The main and unique class of this module, ```tp```, installs the tp cli command (set **tp::cli_enable** to false to avoid that) and offers parameters which allows to configure via Hiera what tp resources to manage.

For each of these parameters (example: **install_hash**) it's possible to set on hiera:

- The hash or resources to manage (**tp::<define>_hash**)
- The merge lookup method to use for the lookup. Default: first (**tp::<define>_hash_merge_behaviour**)
- An hash of deault options for that define's Hash of resources (**tp::<define>_defaults**)

Where **<define>** is any of **install**, **conf**, **dir**, **puppi**, **stdmod**, **concat** and **repo**.

An example to install kubernetes and sysdig, adding the management of the required dependencies:

    tp::install_hash:
      kubernetes:
        auto_prereq: true
      sysdig:
        auto_prereq: true

This is an example of tp::dir hash (with the ensure latest for a git repo for "Tiny Continuous Deployment"):

    tp::dir_hash:
      apache::openskills.info:
        vcsrepo: git
        source: git@git.alvagante.com:web/openskills.info.git
        path: /var/www/html/openskills.info
      apache::abnormalia.com:
        ensure: latest
        vcsrepo: git
        source: git@git.alvagante.org:web/abnormalia.com.git
        path: /var/www/html/abnormalia.com

There are also analogue parameters to handle resources Hashes based on the clients' OS Family for tp::install (**tp::osfamily_install_hash**, **tp::osfamily_install_hash_merge_behaviour**, **tp::osfamily_install_defaults**) and tp::conf (**tp::osfamily_conf_hash**, **tp::osfamily_conf_hash_merge_behaviour**, **tp::osfamily_conf_defaults**) 

Here is an example of OS based install_hash (note the usage of [Yaml merge keys](https://yaml.org/type/merge.html) to avoid data duplication for RedHat and Debian families): 

    linux_tp_install: &linux_tp_install
      filebeat:
        auto_prereq: true
      metricbeat: {}
      auditbeat: {}
      heartbeat-elastic:
        ensure: absent

    tp::osfamily_install_hash:
      RedHat:
        <<: *linux_tp_install
      Debian:
        <<: *linux_tp_install
      windows:
        chocolateygui: {}
        docker-desktop: {}
        powertoys: {}
        MobaXTerm: {}
        Sysinternals: {}


## Updating tiny data and using alternative data sources

By default Tiny Puppet uses the [tinydata](https://github.com/example42/tinydata) module to retrieve data for different applications, but it's possible to override its settings in two ways:

- Via the settings_hash parameter
- Via the data_module parameter

The ```settings_hash``` parameter, present in all tp defines, allows the override of specific settings coming from tiny data.

The names of the available settings are defined in the [tp::settings data type](https://github.com/example42/puppet-tp/blob/master/types/settings.pp). Usage can be as follows:

    tp::install { 'redis':
      settings_hash => {
        'package_name'     => 'my_redis',
        'config_file_path' => '/opt/etc/redis',
      },
    }

The ```data_module``` parameter allows to use a totally different module for tinydata:

    tp::install { 'apache':
      data_module => 'my_data', # Default: tinydata
    }

In this custom data module we have to reproduce the structure of tinydata in order to make it work with tp.

If we want to use our own data module for all our applications, we might prefer to set the following resource defaults in our main manifest (```manifest/site.pp```, typically):

    Tp::Install {
      data_module  => 'my_data',
    }
    Tp::Conf {
      data_module  => 'my_data',
    }
    Tp::Dir {
      data_module  => 'my_data',
    }

Starting from version 2.3.0 (with tinydata version > 0.3.0) tp can even install applications for which there's actually no tinydata defined. In this case just the omonimous package is installed and a warning about missing tinydata is shown. In these cases other defines like tp::conf don't work.

## Usage on the command line

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

* ```tp``` Offers entry points for data driven management of tp resources, and the possibility to install the tp command

### Defined types

- ```tp::install```. It installs an application and starts its service, by default
- ```tp::conf```. It allows to manage configuration files
- ```tp::dir```. Manages the content of directories
- ```tp::stdmod```. Manages the installation of an application using StdMod compliant parameters
- ```tp::test```. Allows quick and easy (acceptance) testing of an application 
- ```tp::repo```. Manages extra repositories for the supported applications
- ```tp::puppi```. Puppi integration (Don't worry, fully optional) 

### Types

* [tp::settings], validates all the possible setting for tinydata

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

Starting from version 3 Tiny Puppet requires Hiera data in module, available from Puppet 4.9.

Version 2.x of Tiny Puppet is compatible with Puppet 4.4 or later and PE 2016.1.1 or later.

Version 1.x is compatible also with Puppet 3, using the 3.x compatible defines (with the ```3``` suffix, like ```tp::install3```).

Version 0.x of Tiny Puppet is compatible by default with Puppet 3 (```tp::install```) and have Puppet 4 / future parser version,with the ```4``` suffix, like ```tp::install4```).

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


## Additional info

You can experiment and play with Tiny Puppet and see a lot of use examples on [Example42's PSICK control-repo](https://github.com/example42/psick) and the [psick module](https://github.com/example42/puppet-psick).

Tiny Puppet has a [website](https://tiny-puppet.com/).

The following blog posts, newest first, have been written on Tiny Puppet, older ones might contain not updated information:

- [Managing extra repositories with Tiny Puppet](https://blog.example42.com/2020/05/21/managing-extra-repositories-with-tiny-puppet/){:target="_blank"}
- [Five Years of Tiny Puppet](https://blog.example42.com/2020/04/20/five-years-of-tiny-puppet/){:target="_blank"}
- [Request for Tiny Data - Part 4 - Defaults and final call](https://blog.example42.com/2019/12/19/request-for-tinydata-part4/){:target="_blank"}
- [Request for Tiny Data - Part 3 - Tiny. fancy and powerful features](https://blog.example42.com/2019/12/16/request-for-tinydata-part3/){:target="_blank"}
- [Request for Tiny Data - Part 2 - Tiny data exposed](https://blog.example42.com/2019/12/12/request-for-tinydata-part2/){:target="_blank"}
- [Request for Tiny Data - Part 1 - Tiny Puppet (tp)](https://blog.example42.com/2019/12/09/request-for-tinydata-part1/){:target="_blank"}
- [Custom applications management using Tiny Puppet](https://www.example42.com/2018/10/15/application-management-using-tinypuppet/){:target="_blank"}
- [tp install anything (anywhere),and configure](https://www.example42.com/2018/09/10/tp-install-anything-and-configure/){:target="_blank"}
- [A few steps to Tiny Puppet on the command line](https://www.example42.com/2018/07/23/a-few-steps-to-tiny-puppet-command-line/){:target="_blank"}
- [Tiny Puppet 1.0](https://blog.example42.com/2015/11/18/tp-1-release/){:target="_blank"}
- [Preparing for Tiny Puppet 1.0](https://blog.example42.com/2015/10/26/preparing-for-tp-1/){:target="_blank"}
- [Introducing Tiny Puppet](https://blog.example42.com/2015/01/02/introducing-tiny-puppet/){:target="_blank"}

