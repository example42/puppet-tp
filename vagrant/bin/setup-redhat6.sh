#!/bin/bash
cd /root

case "$1" in
  original) puppetsuffix='' ;;
  latest) puppetsuffix='' ;;
  *) puppetsuffix="-${1}.el6" ;;
esac

echo "## Installing Puppet "

rpm -qi epel-release >/dev/null 
if [ "x$?" == "x1" ] ; then
  rpm -ivh http://mirror.oss.maxcdn.com/epel/6/i386/epel-release-6-8.noarch.rpm >/dev/null # 2>&1
fi

# Puppetlabs' repo conflicts with SCL Ruby 193
#if [ "x$1" != "xoriginal" ] ; then
#  rpm -qa | grep puppetlabs-release >/dev/null # 2>&1
#  if [ "x$?" == "x1" ] ; then
#    rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm >/dev/null # 2>&1
#  fi
#fi

rpm -qi puppet$puppetsuffix >/dev/null 2>&1
if [ "x$?" == "x1" ] ; then
  yum install -y puppet$puppetsuffix >/dev/null # 2>&1
fi


echo "## Installing SCL and Ruby 193"
package=ruby-1.9.3.p547-1.el6.x86_64.rpm
[ -f /tmp/$package ] || wget --quiet http://rpms.southbridge.ru/rhel6/ruby-1.9.3/x86_64/$package -O /tmp/$package
rpm -qi ruby193 >/dev/null 2>&1
if [ "x$?" == "x1" ] ; then
  yum install -y /tmp/$package
fi
