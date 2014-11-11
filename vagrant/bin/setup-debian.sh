#!/bin/bash
codename=$(facter lsbdistcodename)

cd /root
case "$1" in
  original) puppetsuffix='' ;;
  latest) puppetsuffix='' ;;
  *) puppetsuffix="=${1}puppetlabs1" ;;
esac

if [ "x$1" != "xoriginal" ] ; then
  if [ ! -f puppetlabs-release-precise.deb ] ; then 
    echo "## Installing Puppetlabs repository"
    wget -q http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb >/dev/null 
    dpkg -i puppetlabs-release-${codename}.deb >/dev/null 
    apt-get update >/dev/null 
  fi
fi

echo "## Installing Puppet and its dependencies"
dpkg -s puppet >/dev/null 2>&1 || apt-get update >/dev/null 2>&1 ; apt-get install puppet$puppetsuffix puppet-common$puppetsuffix -y >/dev/null 

