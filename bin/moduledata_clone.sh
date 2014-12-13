#!/bin/bash

showhelp () {
cat << EOF

This script clones and renames the directory of a module data

Usage:
$0 -m test
Create a module data dir based on test module data

$0 -m wget -n vim
Create a module data dir based on wget module data

EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
  -m)
    module=$2
    shift 2 ;;
  -n)
    name=$2
    shift 2 ;;
  esac
done

showhelp

clone_from_module() {
  if [ ! -f data/$module/hiera.yaml ] ; then
    echo "I don't find data/$module/hiera.yaml "
    echo "Run this script from the base tp directory and specify a valid source moduledata"
    exit 1
  fi

  OLDMODULE=$module
  OLDMODULESTRING=$module

  clone
}

function clone() {
  echo
  if [ x$name == 'x' ] ; then
    echo -n "Enter the name of the new module data to create:"
    read NEWMODULE
  else
    NEWMODULE=$name
  fi
  
  if [ -f data/$NEWMODULE/hira.yaml ] ; then
    echo "Data for $NEWMODULE already exists."
    echo "Move or delete it if you want to recreate it. Quitting."
    exit 1
  fi
  
  echo "COPYING MODULE"
  mkdir data/$NEWMODULE
  rsync -av --exclude=".git" --exclude "spec/fixtures" data/$OLDMODULE/ data/$NEWMODULE


  echo "---------------------------------------------------"
  echo "CHANGING FILE CONTENTS"
  for file in $( grep -R $OLDMODULESTRING data/$NEWMODULE | cut -d ":" -f 1 | uniq ) ; do
    # Detect OS
    if [ -f /System/Library/Accessibility/AccessibilityDefinitions.plist ] ; then
#    if [ -f /mach_kernel ] ; then
      sed -i "" -e "s/$OLDMODULESTRING/$NEWMODULE/g" $file && echo "Changed $file"
    else
      sed -i "s/$OLDMODULESTRING/$NEWMODULE/g" $file && echo "Changed $file"
    fi

  done

  echo "Data for $NEWMODULE created"
  echo "Start to edit the files in data/$NEWMODULE/ to customize it"

}

clone_from_module

