---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

## Operating Systems support

Tiny Puppet is currently developed and mostly tested on Ruby 1.9.3, it's expected to work on more recent versions and **does not** work on Ruby 1.8.7.

This means that our Puppet Master should run on stock setups on these OS:
  - Ubuntu 14.04
  - Debian 7 and 8
  - RedHat 7
  - CentOS 7

Our clients may run on different Operating Systems and are actually supported in TP data, in fact, to run acceptance tests on other OS a compatible Ruby version is pre-installed in the provisioning of the relevant Vagrant boxes:
  - Ubuntu 12.04
  - Debian 6
  - CentOS 6

Tiny Puppet works on Puppet 2.x, 3.x and 4.x (see below for differences in TP versions).

**IMPORTANT NOTE**: Do not expect all the applications to flawlessly work out of the box for all the Operating Systems. Tiny Puppet manages applications that can be installed and configured using the underlying OS native packages and services, this might not be possible for all the cases.

A summary of support for different applications on different Operating Systems is available in the [Compatibility Matrix](https://github.com/example42/tp-acceptance/blob/master/tests/app_summary.md).


## Prerequisites

Tiny Puppet requires these Puppet modules:

 - The [tinydata](https://github.com/example42/tinydata) module

 - Puppet Labs' [stdlib](https://github.com/puppetlabs/puppetlabs-stdlib) module.

If we use the relevant defines, other dependencies are needed:

  - Define ```tp::concat``` requires Puppet Labs' [concat](https://github.com/puppetlabs/puppetlabs-concat) module.

  - Define ```tp::dir``` , when used with the ```vcsrepo``` argument, requires Puppet Labs' [vcsrepo](https://github.com/puppetlabs/puppetlabs-vcsrepo) module.

  - Define ```tp::puppi``` requires Example42's [puppi](https://github.com/example42/puppi) module.

## Difference between tp versions 0.x and 1.x

Since Tiny Puppet version 1.x the main tp defines are compatible only with Puppet 4 or Puppet 3 with future parser enabled. In environments where we have Puppet 3 (or earlier) we can use the relevant defines with the 3 prefix.

On tp version 0.x the defaults are different: the default defines are compatible with any Puppet version and Puppet 4 versions have the 4 suffix.

So, summing up, on tp (0.9.x) there is a layout for defines as follows:

    tp::install  # Works on Puppet 2, 3 and 4
    tp::install3 # Works on Puppet 2, 3 and 4, the same of of tp::install
    tp::install4 # Optimized for Puppet 4 (doesn't work on earlier versions)

On tp 1.x the naming is as follows:

    tp::install  # Optimized for Puppet 4 (doesn't work on earlier versions)
    tp::install3 # Works on Puppet 2, 3 and 4 the same of tp::install from 0.x
