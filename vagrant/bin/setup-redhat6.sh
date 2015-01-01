#!/bin/bash
cd /root

case "$1" in
  original) puppetsuffix='' ;;
  latest) puppetsuffix='' ;;
  *) puppetsuffix="-${1}.el6" ;;
esac

echo "## Installing latest Puppet version and dependencies"

rpm -qi epel-release >/dev/null 
if [ "x$?" == "x1" ] ; then
  rpm -ivh http://ftp.colocall.net/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm >/dev/null # 2>&1
fi

if [ "x$1" != "xoriginal" ] ; then
  rpm -qa | grep puppetlabs-release >/dev/null # 2>&1
  if [ "x$?" == "x1" ] ; then
    rpm -ivh https://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-11.noarch.rpm >/dev/null # 2>&1
  fi
fi

rpm -qi puppet$puppetsuffix >/dev/null 2>&1
if [ "x$?" == "x1" ] ; then
  yum install -y puppet$puppetsuffix >/dev/null # 2>&1
fi


echo "## Installing SCL and Ruby 193"
rpm -qi centos-release-SCL >/dev/null 2>&1
if [ "x$?" == "x1" ] ; then
  yum install -y centos-release-SCL
fi

rpm -qi ruby193 >/dev/null 2>&1
if [ "x$?" == "x1" ] ; then
  yum install -y ruby193
fi

grep 'PATH LD_LIBRARY_PATH PKG_CONFIG_PATH MAN_PATH' /etc/sudoers || echo 'Defaults    env_keep += "PATH LD_LIBRARY_PATH PKG_CONFIG_PATH MAN_PATH"' >> /etc/sudoers
