## Usage with Hiera

You may find useful the ```create_resources``` defines that are feed, in the main ```tp``` class by special ```hiera_hash``` lookups that map all the available ```tp``` defines to hiera keys in this format ```tp::<define>_hash```.

Although such approach is very powerful (and totally optional) we recommend not to abuse of it.

Tiny Puppet is intended to be used in modules like profiles, your data should map to parameters of such classes, but if you want to manage directly via Hiera some tp resources you have to include the main class:

    include tp

This is automatically done when you use ```tp::install``` with the ```cli_enable``` option set to true (this is the default behaviour).

In the class are defined Hiera lookups (using hiera_hash so thy are recursive (and this may hurt a log when abusing) that expects parameters like the ones in the following sample in Yaml.

As an handy add-on, a ```create_resources``` is run also on the variables ```tp::packages```, ```tp::services```, ```tp::files``` to eventually manage the relevant Puppet resource types.

On hiera yaml files then you can have somethig as follows (not actually recommended, but useful to understand the usage basic patterns):


    ---
      tp::install_hash:
        memcache:
          ensure: present
        apache:
          ensure: present
        mysql:
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

Check the [Example42 Puppet modules](https://github.com/example42/puppet-modules) control repo for sample data and code organisation in a tp based setup.

