#!/bin/bash

# Source common functions
. $(dirname $0)/functions || exit 10

# RegExp for whitelist of programs to not uninstall after test
uninstall_whitelist='ssh|vim|lsb'

show_help () {
  echo
  echo "You must specify the application you want to test and the VM to use:"
  echo "$0 <application> <vm> [acceptance]"
  echo
  echo "To test redis on Ubuntu1404:"
  echo "$0 redis Ubuntu1404"
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
options="$PUPPET_OPTIONS --verbose --report --show_diff --pluginsync --summarize --modulepath '/vagrant/vagrant/modules/local:/vagrant/vagrant/modules/:/vagrant/vagrant/modules/public:/etc/puppet/modules' "
command="sudo puppet apply"

acceptance_test () {
  echo_title "Running acceptance test for $1 on $2"
  rm -f acceptance/$2/success/$1
  rm -f acceptance/$2/failure/$1
  vagrant ssh $2 -c "sudo /etc/puppi/checks/$1" > /tmp/tp_test_$1
  if [ "x$?" == "x0" ]; then
    mkdir -p acceptance/$2/success
    mv /tmp/tp_test_$1 acceptance/$2/success/$1
    echo_success "SUCCESS! Output written to acceptance/$2/success/$1"
  else
    mkdir -p acceptance/$2/failure
    mv /tmp/tp_test_$1 acceptance/$2/failure/$1
    echo_failure "FAILURE! Output written to acceptance/$2/failure/$1"
  fi

  if [[ "$1" =~ $uninstall_whitelist ]]; then
    echo_title "Skipping Uninstallation of $1 on $2"
  else
    echo_title "Uninstalling $1 on $2"
    vagrant ssh $2 -c "$command $options -e 'tp::install { $1: ensure => absent }'"
  fi
}

if [ "x${app}" == "xall" ]; then
  for a in $(ls -1 data | grep -v default.yaml) ; do
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

