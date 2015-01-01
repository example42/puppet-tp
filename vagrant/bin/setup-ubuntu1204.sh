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

echo "## Installing Ruby 1.9.3"
dpkg -s ruby1.9.1 >/dev/null 2>&1 || apt-get update >/dev/null 2>&1 ; apt-get install -y ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev  >/dev/null 

update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 \
         --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                   /usr/share/man/man1/ruby1.9.1.1.gz \
         --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
         --slave   /usr/bin/irb irb /usr/bin/irb1.9.1 \
         --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1

update-alternatives --config ruby
update-alternatives --config gem
