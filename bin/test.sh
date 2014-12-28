#!/bin/bash

show_help () {
  echo
  echo "You must specify the application you want to test and the VM to use:"
  echo "$0 <application> <vm> [test]"
  echo
  echo "To test redis on Ubuntu1404:"
  echo "$0 redis Ubuntu1404"
  echo
  echo "To test redis on all Vagrant VMs:"
  echo "$0 redis all"
  echo
  echo "To test all apps on Ubuntu1404:"
  echo "$0 all Ubuntu1404 "
  echo
  echo "To test all apps on Ubuntu1404 and save tests results:"
  echo "$0 redis Ubuntu1404 acceptance"
}

if [ "x$2" == "x" ]; then
  show_help
  exit 1
fi

app=$1
vm=$2
if [ "x$3" == "xacceptance" ]; then
  acceptance=yes
  puppi_string="puppi_enable => true,"
else
  acceptance=no
  puppi_string=""
fi

options="--verbose --report --show_diff --pluginsync --summarize --modulepath '/tmp/vagrant-puppet-1/modules-0:/tmp/vagrant-puppet-1/modules-1:/tmp/vagrant-puppet-1/modules-2:/etc/puppet/modules' "
command="sudo puppet apply"

echo_title () {
  echo
  echo
  echo -en "\\033[0;35m"
  echo "$1"
  echo -en "\\033[0;32m"
}

acceptance_test () {
  echo_title "Running acceptance test for $1 on $2"
  vagrant ssh $2 -c "sudo /etc/puppi/checks/$1" > /tmp/tp_test_$1
  if [ "x$?" == "x0" ]; then
    mkdir -p acceptance/$2/success
    mv /tmp/tp_test_$1 acceptance/$2/success/$1
    echo_title "SUCCESS! Output written to acceptance/$2/success/$1"
  else
    mkdir -p acceptance/$2/failure
    mv /tmp/tp_test_$1 acceptance/$2/failure/$1
    echo_title "FAILURE! Output written to acceptance/$2/failure/$1"
  fi

  echo_title "Uninstalling $1 on $2"
  vagrant ssh $2 -c "$command $options -e 'tp::install { $1: ensure => absent }'"

}

if [ "x${app}" == "xall" ]; then
  for a in $(ls data) ; do
    echo_title "Installing $a on $vm"
    vagrant ssh $vm -c "$command $options -e 'tp::install { $a: $puppi_string }'"
    if [ "x${acceptance}" == "xyes" ]; then
      acceptance_test $a $vm
    fi
  done
else
  echo_title "Installing $app on $vm"
  vagrant ssh $vm -c "$command $options -e 'tp::install { $app: $puppi_string }'" 
  if [ "x${acceptance}" == "xyes" ]; then
    acceptance_test $app $vm
  fi
fi

