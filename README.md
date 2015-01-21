# Tiny Puppet 

## Yet Another Puppet Abstraction Layer

Tiny Puppet is single Puppet module that manages virtually any application.

It can replace or integrate existing component application modules.


It features:

  - Quick, easy to use, standard, coherent, powerful interface to the managed resources

  - Out of the box and easily expandable support for most common Operating Systems

  - Modular data source design. Support for an easily growing [set of applications](https://github.com/example42/puppet-tp/tree/master/data).

  - Smooth coexistence with any existing Puppet modules setup: you decide what to manage

It is intended to be used in modules that operate at an higher abstraction layer (local site modules, profiles and so on) where we assemble and use different application modules to achieve the setup we need.

The expected user is a SysAdmin who knows how to configure his|her applications and wants a quick way to manage then without the need to "study" and include in the local modulepath a dedicated public module, or, even worse, write a new one from scratch.


## Provided Resources

Tiny Puppet provides the following defines:

- ```tp::install```. It installs an application and starts its service, by default
- ```tp::conf```. It allows to manage configuration files
- ```tp::dir```. Manages the content of directories
- ```tp::stdmod```. Manages the installation of an application using StdMod compliant parameters
- ```tp::line```. (TODO) Manages single lines in a configuration file
- ```tp::repo```. Manages extra repositories for the supported applications
- ```tp::concat```. (WIP) Manages file fragments of a configuration file
- ```tp::instance```. (TODO) Manages an application instance
- ```tp::puppi```. Puppi integration (Don't worry, fully optional) 
- ```tp::test```. Allows quick and easy (acceptance) testing of an application 
- ```tp::netinstall```. (WIP) Installs from a remote url
- ```tp::github```. (TODO) Installs (anything?;) directly from GitHub source


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

Tiny Puppet requires Puppet Labs' [stdlib](https://github.com/puppetlabs/puppetlabs-stdlib) module.

If you use the relevant defines, other dependencies are needed:

```tp::concat``` requires Puppet Labs' [concat](https://github.com/puppetlabs/puppetlabs-concat) module.

```tp::dir``` , when used with the ```vcsrepo``` argument, requires Puppet Labs' [vcsrepo](https://github.com/puppetlabs/puppetlabs-vcsrepo) module.

```tp::puppi``` requires Example42's [puppi](https://github.com/example42/puppi) module.


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


### Managing repositories

Currently Tiny Puppet supports applications' installation only via the OS native packaging system. In order to cope with software which may not be provided by default on an OS, TP provides the ```tp::repo``` define that manages YUM and APT repositories for RedHat and Debian based Linux distributions.

The data about a repository is managed as all the other data of Tiny Puppet. Find [here](https://github.com/example42/puppet-tp/blob/master/data/elasticsearch/osfamily/Debian.yaml) an example for managing Apt repositories and [here](https://github.com/example42/puppet-tp/blob/master/data/elasticsearch/osfamily/RedHat.yaml) one for Yum ones.

Generally you don't have to use directly the ```tp::repo``` defind, as, when the repository data is present, it's automatically added from the ```tp::install``` one.

If, for whatever reason, you don't want to automatically manage a repository for an application, you can set to ```false``` the ```auto_repo``` parameter, and, eventually you can manage the repository in a custom dependency class:

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

You can test Tiny Puppet on different Operating Systems with Vagrant:

    vagrant status

The default Vagrantfile uses the cachier plugin, you can install it with:

    vagrant plugin install vagrant-cachier

You absolutely need to have the VirtualBox guest additions working on the Vagrant's VMs, if the provided ones are not updated you may use the VBguest plugin to automatically install them:

    vagrant plugin install vagrant-vbguest

Besides the ```Vagrantfile``` all the Vagrant stuff is under the ```vagrant``` directory.

The default manifest is ```vagrant/manifests/site.pp```, you can play with Tiny Puppet there and verify there what you can do with it.

Public modules, which are required or optional dependencies for Tiny Puppet are under ```vagrant/modules/public```, populate them with Librarian Puppet:

    librarian-puppet install --puppetfile Puppetfile --path vagrant/modules/public

On the shell of your VM you can run Puppet (same effect of ```vagrant provision```) with:

    root@ubuntu1404:/#  /vagrant/bin/papply_vagrant.sh 

this does a puppet apply on /vagrant/vagrant/manifests/site.pp with the correct parameters.

If you specify a different manifest, puppet apply is done on it:

    root@ubuntu1404:/#  /vagrant/bin/papply_vagrant.sh test.pp 

### Acceptance tests

The ```bin/test.sh``` script is the quickest way to test how Tiny Puppet manages different applications on different Operating Systems.

You need to run the VM you want to test on:

    vagrant up Ubuntu1404

and then execute commands like these:

  - To test apache installation on Ubuntu1404:

    ```bin/test.sh apache Ubuntu1404```

  - To test ALL the supported applications on Centos7:

    ```bin/test.sh all Centos7```

  - To test ALL the applications on Centos7 and save the results in the ```acceptance``` dir:

    ```bin/test.sh all Centos7 acceptance```

  - To run puppi check for proftpd applications on Centos7:

    ```bin/test.sh all Centos7 puppi```


Do not expect everything to work seamlessly, this is a test environment to verify functionality and coverage on different Operating Systems. 


### Compatibility matrix

Routinely the results of acceptance tests are saved in the [```acceptance```](https://github.com/example42/puppet-tp/tree/master/acceptance)  directory: use it as a reference on the current support matrix of different applications on different Operating Systems.

Note however that Tiny Puppet support may extend to other OS: the acceptance tests use directly ```puppet apply``` on ```tp``` defines, so they need to run locally and have the expected prerequisites (such as the Ruby version).

Note also that some tests fail for trivial reasons such as the absence of a valid configuration file by default or missing data to configure dedicated repositories or execution order issues while running tests on the same VM or errors in the test scripts.

Check the output of the check scripts, under the ```success``` and ```failure``` directories for some details on the reasons some tests are failing.


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


[![Build Status](https://travis-ci.org/example42/puppet-tp.png?branch=master)](https://travis-ci.org/example42/puppet-tp)
[![Coverage Status](https://coveralls.io/repos/alvagante/puppet-tp/badge.png)](https://coveralls.io/r/alvagante/puppet-tp)
