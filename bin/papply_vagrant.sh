#!/bin/sh

if [ $1  ]; then
  manifest=$1
else
  manifest="/vagrant/vagrant/manifests/site.pp"
fi

puppet apply --verbose --report --show_diff --pluginsync --summarize --modulepath "/vagrant/vagrant/modules/local:/vagrant/vagrant/modules:/vagrant/vagrant/modules/public:/etc/puppet/modules" --hiera_config=/vagrant/vagrant/hiera.yaml --manifestdir /vagrant/vagrant/manifests --detailed-exitcodes $manifest

