#!/bin/bash
cd /root

case "$1" in
  original) puppetsuffix='' ;;
  latest) puppetsuffix='' ;;
  *) puppetsuffix="-${1}.el6" ;;
esac

echo "## Installing Puppet version and dependencies"

zypper addrepo -f http://download.opensuse.org/repositories/systemsmanagement:/puppet/SLE_11_SP2/ puppet
zypper install puppet

