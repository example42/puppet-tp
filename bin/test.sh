#!/bin/bash

# Source common functions
. $(dirname $0)/functions || exit 10

# RegExp for whitelist of programs to not uninstall after test
uninstall_whitelist='ssh|vim|lsb|puppet|apt'

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
  echo "To test all apps on Ubuntu1404 and save acceptance tests results:"
  echo "$0 redis Ubuntu1404 acceptance"
  echo
  echo "To run puppi check on Ubuntu1404 and puppi checks results:"
  echo "$0 redis Ubuntu1404 puppi"
}

if [ "x$2" == "x" ]; then
  show_help
  exit 1
fi

app=$1
vm=$2
mode=$3
case $mode in 
    acceptance) mode_param="test_enable => true," ;;
    puppi) mode_param="puppi_enable => true," ;;
esac

# Workaround to use Ruby 193 on Centos6
if [ "x$vm" == "xCentos65" ]; then
  envs="env PATH=/opt/rh/ruby193/root/usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/vagrant/bin LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64"
else
  envs=''
fi

options="$PUPPET_OPTIONS --verbose --report --show_diff --pluginsync --summarize --modulepath '/vagrant/vagrant/modules/local:/vagrant/vagrant/modules/:/vagrant/vagrant/modules/public:/etc/puppet/modules' "
command="sudo $envs puppet apply"

acceptance_test () {
  echo_title "Running acceptance test for $1 on $2"
  rm -f acceptance/$2/success/$1
  rm -f acceptance/$2/failure/$1
  vagrant ssh $2 -c "sudo /etc/tp/test/$1" > /tmp/tp_test_$1_$2
  if [ "x$?" == "x0" ]; then
    mkdir -p acceptance/$2/success
    mv /tmp/tp_test_$1_$2 acceptance/$2/success/$1
    cat acceptance/$2/success/$1
    echo_success "SUCCESS! Output written to acceptance/$2/success/$1"
  else
    mkdir -p acceptance/$2/failure
    mv /tmp/tp_test_$1_$2 acceptance/$2/failure/$1
    cat acceptance/$2/failure/$1
    echo_failure "FAILURE! Output written to acceptance/$2/failure/$1"
  fi

  if [[ "$1" =~ $uninstall_whitelist ]]; then
    echo_title "Skipping Uninstallation of $1 on $2"
  else
    echo_title "Uninstalling $1 on $2"
    vagrant ssh $2 -c "$command $options -e 'tp::install { $1: ensure => absent }'"
  fi
}

puppi_check () {
  echo_title "Running puppi check for $1 on $2"
  vagrant ssh $2 -c "sudo puppi check"
  if [ "x$?" == "x0" ]; then
    echo_success "SUCCESS!"
  else
    echo_failure "FAILURE!"
  fi
}


if [ "x${app}" == "xall" ]; then
  for a in $(ls -1 data | grep -v default.yaml | grep -v test) ; do
    echo_title "Installing $a on $vm"
    vagrant ssh $vm -c "$command $options -e 'tp::install { $a: $mode_param }'"
    if [ "x${mode}" == "xacceptance" ]; then
      acceptance_test $a $vm
    fi
    if [ "x${mode}" == "xpuppi" ]; then
      puppi_check $a $vm
    fi
  done
else
  echo_title "Installing $app on $vm"
  vagrant ssh $vm -c "$command $options -e 'tp::install { $app: $mode_param }'" 
  if [ "x${mode}" == "xacceptance" ]; then
    acceptance_test $app $vm
  fi
  if [ "x${mode}" == "xpuppi" ]; then
    puppi_check $app $vm
  fi
fi

