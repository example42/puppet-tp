---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

# Essential Applications Management

Tiny Puppet is a Puppet module that allows management of virtually any application on any Operating System.

It's based on the assumption that its user knows and wants to control how to shape the managed application's configuration files.

It features:

- Quick, easy to use, standard, coherent, powerful interface to install packages, manage services and  configuration files, in whatever way preferred.

- Out of the box and easily expandable support for most common Operating Systems.

- Modular data source design. Support for an easily growing set of applications.

- Smooth coexistence with any existing Puppet modules setup: according to situations and needs can be used as alternative or complementary to normal component modules.

All the data used by Tiny Puppet to support different applications is stored in the separated module ([tinydata](https://github.com/example42/tinydata).

This is the list of the currently [supported applications](https://github.com/example42/tinydata/tree/master/data).


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
