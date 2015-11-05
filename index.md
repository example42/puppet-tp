---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

# Tiny Puppet

Tiny Puppet is single Puppet module that manages virtually any application.

It can replace or integrate existing component application modules.

It features:

- Quick, easy to use, standard, coherent, powerful interface to the managed resources

- Out of the box and easily expandable support for most common Operating Systems

- Modular data source design. Support for an easily growing set of applications.

- Smooth coexistence with any existing Puppet modules setup: you decide what to manage

Application data stored in a configurable separated module ([tinydata](https://github.com/example42/tinydata) is the default source for applications data)


## Tiny Puppet defines

Tiny Puppet provides the following defines:

- ```tp::install```. It installs an application and starts its service, by default
- ```tp::conf```. It allows to manage configuration files
- ```tp::dir```. Manages the content of directories
- ```tp::stdmod```. Manages the installation of an application using StdMod compliant parameters
- ```tp::test```. Allows quick and easy (acceptance) testing of an application
- ```tp::repo```. Manages extra repositories for the supported applications
- ```tp::puppi```. Puppi integration (Don't worry, fully optional)

The following defines are Work In Progress or planned / envisioned:

- ```tp::concat```. (WIP) Manages file fragments of a configuration file
- ```tp::netinstall```. (WIP) Installs from a remote url
- ```tp::instance```. (TODO) Manages an application instance
- ```tp::line```. (TODO) Manages single lines in a configuration file
- ```tp::github```. (TODO) Installs (anything?;) directly from GitHub source
