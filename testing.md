---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

# Testing with tp

One of Tiny Puppet defines is ```tp::test```: it creates a script on the file systems that tests if the application is correctly installed and its eventual service is running.

This script can be used for any purpose: acceptance tests, monitoring, continuous integration.

Usage is as simple as:

    tp::test { 'redis': }

It's possible to add testing also while installing an application, with:

    tp::install { 'redis':
      test_enable => true,  # Default: false
    }

By default ```tp::test``` uses [this template](https://github.com/example42/puppet-tp/blob/master/templates/test/acceptance.erb) for the test script, but it's possible to provide a custom one in either of these ways:

    tp::test { 'redis':
      template => 'site/tp/test/test.erb',
    }

    tp::install { 'redis':
      test_enable   => true,
      test_template => 'site/tp/test/test.erb',
    }

The location of this script is determined by the ```base_dir``` parameter of ```tp::test```, the default value is ```/etc/tp/test/```, so we can run the above script, from the node's shell, executing:

    /etc/tp/test/redis


# Acceptance tests

Since ```tp::test``` uses the same settings data used by ```tp::install```, it's able to automatically test any new application without the need to write separated tests.

This comes incredibly handy when we want to run acceptance tests on what we install via tp.

In the [/playground.html](Tiny Puppet Playground) there's the ```bin/test.sh``` script which allows quick testing of supported applications on the Operating Systems available in the Vagrant playground.

We just need to run the VM we want to test on:

    vagrant up Ubuntu1404

and then execute commands like these:

  - To test apache installation on Ubuntu1404:

        bin/test.sh apache Ubuntu1404

  - To test ALL the supported applications on Centos7:

        bin/test.sh all Centos7

  - To test ALL the applications on Centos7 and save the results in the ```acceptance``` dir:

        bin/test.sh all Centos7 acceptance

  - To test an application on all the running VMs and save the results in the ```acceptance``` dir:

        bin/test.sh munin all acceptance

  - To run puppi check for proftpd applications on Centos7:

        bin/test.sh all Centos7 puppi

   - To test all the applications on all the running VMs saving the output in the acceptance dir:

        bin/test.sh all all acceptance

We can even try to test applications not installed via Tiny Puppet: the data we use to test packages and services (and possibly listening ports, somewhen in the future) is the one expected for a given OS.

It's worth reminding that all these tests comes automatically out of the box, once we place new data for new applications, those applications can be tested via ```tp::test``` without the need to write a single line of (testing) code.
