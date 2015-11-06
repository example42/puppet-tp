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


## Using custom data

We have two options at disposal to customize the data used to manage an application:

- Provide a custom data module via the ```data_module``` argument

- Provide custom settings with the ```settings_hash``` argument

Both the arguments are available in all the tp functions.

#### Using a custom data module

The tinydata module is the default module where data is looked for, but you can provide a custom module for your own application settings:

    tp::install { 'apache':
      data_module => 'my_data',
    }

This implies that you need to have a directory like ```my_data/data/apache``` where you have an ```hiera.yaml``` where your hierarchy is described and the relevant yaml files where data for your apache is defined under the ```settings``` key.

You can use a different data module for different tp defines.

#### Providing custom settings

If you don't need to provide a complete separated module, you can override the default tinydata settings for a given application using the ```settings_hash``` parameter, which expects an hash having key names like the settings keys in the tinydata files.

    tp::install { 'apache':
      settings_hash => {
        package_name     => 'my_apache',
        config_file_path => '/etc/my_apache/httpd.conf',
      },
    }

Whenever you use custom settings or a custom data module you will probably need to use the same settings for each define of a given application. For example:

    $nginx_settings = hiera_hash('nginx::settings')
    $nginx_options = hiera_hash('nginx::options')

    tp::install { 'nginx':
      settings_hash => $nginx_settings,
    }
    tp::conf { 'nginx':
      settings_hash => $nginx_settings,
      epp           => 'site/nginx/nginx.conf.epp',
      options_hash  => $nginx_options,
    }

Note the different between the parameters:

- ```settings_hash``` An hash of settings that override the default tiny data for an applications (settings like: package_name, service_name, config_dir_path...)

- ```options_hash``` An hash of application specific options which you can use in your templates as needed (things like, for apache: DocumentRoot, Port, ServerName... ) 


## Update policy

Our commitment is to keep Tiny Data as updated and correct as possible, also if this involves breaking backwards compatibility on existing setups.

Whenever new references to new versions of applications or operating systems (for example in additional repos url) are available, they will be updated.

If existing data for some Operating Systems is incorrect we will update it without caring about possible backwards incompatibilities on existing setups, we won't even follow SemVer rules for tinydata.

The driving principle is to have the correct data for each version of each supported operating system and application.

We recommend to make a local fork of this module and update it from the upstream version only after relevant testing.

Bug reporting or pull request are always welcomed.

For more info on cross OS compatibility testing and status, check the [this](/playground.html) page.
