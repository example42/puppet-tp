#!/bin/sh

puppet apply --verbose --report --show_diff --pluginsync --summarize --evaltrace --trace --modulepath "/vagrant/vagrant/modules/local:/vagrant/vagrant/modules/tp:/vagrant/vagrant/modules/public:/etc/puppet/modules" --hiera_config=/vagrant/vagrant/hiera.yaml --manifestdir /vagrant/vagrant/manifests --detailed-exitcodes /vagrant/vagrant/manifests/site.pp

