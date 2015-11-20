---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

# Essential Application Management

Tiny Puppet is a Puppet module we can use to manage virtually **any application on any Operating System** (here's the current [Compatibility Matrix](https://github.com/example42/tp-acceptance/blob/master/tests/app_summary.md)).

We can install an application and start its eventual services with:

    tp::install { 'apache': }

We can configure its main configuration file with a custom template populated from an custom hash of options with something like:

    tp::conf { 'openssh'
      template     => 'site/openssh/sshd_config.erb',
      options_hash => hiera_hash('openssh::options'),
    }

Tiny Puppet takes care of dependencies (file is managed after the package and triggers a service restart, by default) and correct paths and names for the underlying Operating System.

It *just* assumes that we know how to configure our files, and allows us to have full control on how to shape the data that feeds them.

It also saves us from the efforts to find, understand and integrate a dedicated component module and make it produce the output we need.

We can manage actually any configuration file related to an application. For example to manage directly the content of a file in a ```conf.d``` directory we specify the ```base_dir``` type and the name of the file in the title (in the following example file managed is ```/etc/rsyslog.d/logserver.conf```):

    tp::conf { 'rsyslog::logserver.conf':
      content  => "*.* @@syslog.example.com\n",
      base_dir => 'conf',
    }

In the previous examples the actual paths of the managed files have been somehow automagically calculated, if we don't believe in magics and want to be sure of the path, we can just specify it. In the following example we also set the mode and the name of the epp template we want to use for it.

    tp::conf { 'openssh::root_config': #
      path   => '/root/.ssh/config',
      epp    => 'site/openssh/root/config.epp',
      mode   => '0640',
    }

In this case the title of the define is not used as file name, but it still needs to be set, have the application namespace(```openssh```), and be unique in our catalog (```root_config```):

We can also manage the content or whole directories from a given fileserver:

    tp::dir { 'openssh':
      source => 'puppet:///modules/site/openssh',
    }

And we can even specify the source from a given VCS tool (in this case we place the content of a git repo in the data directory of nginx (exposing directly the content of a repo on a webserver is not a recommended practices, this example is just to give an idea of what can be done):

    tp::dir { 'nginx::website':
      source   => 'https://git.example.com/apps/website/',
      vcsrepo  => 'git',
      base_dir => 'data',
    }

For more details on how to use Tiny Puppet defines and the logic behind some automatic path choices check the [usage](/usage.html) page.

## Features

Tiny Puppet may look like a joke, but it works.

As long as our application can be installed via a native package (Tiny Puppet manages eventual additional repos) and there's the correct [tinydata](https://github.com/example42/tinydata) to handle it.

So, this Tiny Puppet is about:

- A quick, easy to use, coherent, powerful interface to install packages, manage services and  configuration files in the way we want.

- The possibility to manage virtually any application on every OS, with currently about 100 supported applications, which can be easily expanded and fixed.

- A smooth coexistence with any existing Puppet modules setup: according to situations and needs can be used as alternative or complementary to normal component modules.

All the data used by Tiny Puppet to support different applications is stored in the separated [tinydata](https://github.com/example42/tinydata) module. Check [this page](/tinydata.html) for more info about it.


## Tiny Puppet defines

Tiny Puppet provides the following defines:

- ```tp::install```. Install an application and start its service, by default
- ```tp::conf```. Manage configuration files
- ```tp::dir```. Manage the content of directories, also via vcs repositories
- ```tp::stdmod```. Manage an application using StdMod compliant parameters
- ```tp::test```. Allows quick and easy (acceptance) testing of an application
- ```tp::repo```. Manages extra repositories for the supported applications
- ```tp::puppi```. Puppi integration (Don't worry, fully optional)

Other defines are under work, planned or envisioned:

- ```tp::concat```. (WIP) Manages file fragments of a configuration file
- ```tp::netinstall```. (WIP) Installs from a remote url
- ```tp::instance```. (TODO) Manages an application instance
- ```tp::line```. (TODO?) Manages single lines in a configuration file
- ```tp::github```. (TODO) Installs (anything?;) directly from GitHub source
- ```tp::monitor```. (TODO?) Monitor the defined application
- ```tp::firewall```. (TODO?) Firewall the defined application
