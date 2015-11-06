---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

# Tiny Puppet data

The data used by Tiny Puppet to manage different applications on different operating systems is defined in the separated [tinydata](https://github.com/example42/tinydata) module.

Here for each supported application there is a directory inside the ```data/``` dir which contains:

- the ```hiera.yaml``` file which describes the hierarchy to use to lookup for the relevant application data.

- the yaml files where data is stored according to the defined hierarchy.

A sample ```hiera.yaml``` is like this:

    ---
     :hierarchy:
       - "%{title}/osfamily/%{osfamily}"
       - "%{title}/default"
       - default

so the lookup is done, if ```$title == 'mariadb'```  and ```$::osfamily == 'RedHat'``` in these files:

    tinydata/data/mariadb/osfamily/RedHat.yaml
    tinydata/data/mariadb/default.yaml
    tinydata/data/default.yaml

The last file contains general defaults for every application.

Note that even if we use a file called ```hiera.yaml``` to configure the lookup hierarchy for each application, Tiny Puppet DOES NOT currently use Hiera for any of its lookups, it used a custom function called [tp_lookup](https://github.com/example42/puppet-tp/blob/master/lib/puppet/parser/functions/tp_lookup.rb). The behaviour is similar even if Hiera is much more complete, for example we can interpolate variables in tinydata.


## Update policy

Our commitment is to keep Tiny Data as updated and correct as possible, also if this involves breaking backwards compatibility on existing setups.

Whenever new references to new versions of applications or operating systems (for example in additional repos url) are available, they will be updated.

If existing data for some Operating Systems is incorrect we will update it without caring about possible backwards incompatibilities on existing setups, we won't even follow SemVer rules for tinydata.

The driving principle is to have the correct data for each version of each supported operating system and application.

We recommend to make a local fork of this module and update it from the upstream version only after relevant testing.

Bug reporting or pull request are always welcomed.

For more info on cross OS compatibility testing and status, check the [this](/playground.html) page.
