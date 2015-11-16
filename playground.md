---
layout: home
title: 'Tiny Puppet - Essential Applications Management'
subTitle: 'Yet Another Puppet Abstraction layer'
---

# Tiny Puppet Playground

The [Tiny Puppet Playground](https://github.com/example42/tp-playground) is a Vagrant environment where we can experiment and test tp on different operating systems.

To install and setup the playground:

    git clone https://github.com/example42/tp-playground
    cd tp-playground

Public modules, which are required or optional dependencies for Tiny Puppet are expected under ```modules```, we can populate them with Librarian Puppet Simple (installed as gem with ```gem install librarian-puppet-simple```):

    librarian-puppet install --puppetfile Puppetfile --path modules

or r10k (```gem install r10k```):

    r10k puppetfile install

We can test Tiny Puppet on different Operating Systems using the provided Vagrant environment:

    vagrant status

The default [Vagrantfile](https://github.com/example42/tp-playground/blob/master/Vagrantfile#L3) uses the cachier plugin, we can install it with with:

    vagrant plugin install vagrant-cachier

If we don't want to use this plugin we have to comment the second line of Vagrant file:

    # config.cache.auto_detect = true

We need to have the VirtualBox guest additions working on the Vagrant's VMs, if the provided ones are not updated we may use the VBguest plugin to automatically install them (this is optional):

    vagrant plugin install vagrant-vbguest

Besides the ```Vagrantfile``` all the Vagrant specific stuff is under the ```vagrant``` directory.

The default manifest is ```vagrant/manifests/site.pp```, we can quickly play with Tiny Puppet there adding tp defines and seeing the effect on our VMs.

On the shell of our VM we can run Puppet (same effect of ```vagrant provision```) with:

    root@ubuntu1404:/#  /vagrant/bin/papply_vagrant.sh

this does a ```puppet apply``` on ```/vagrant/manifests/site.pp``` with the correct parameters.

If we specify a different manifest, puppet apply is done on it:

    root@ubuntu1404:/#  /vagrant/bin/papply_vagrant.sh /vagrant/manifests/test.pp
