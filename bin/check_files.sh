#!/usr/bin/env bash
# Script originally written by Janne Pohjolainen (https://github.com/messis-rocket)

YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CLR=$(tput sgr0)

PUPPET=$(which puppet)
ERB=$(which erb)
RUBY=$(which ruby)

if [ ! -z ${PUPPET} ]; then
  echo "${YELLOW}Validating Manifests.${CLR}"

  for i in $(find manifests -name '*.pp')
  do
    echo -ne "$i - "
    err=$(${PUPPET} parser validate $i 2>&1)
    if [ $? = 0 ]; then
      echo "${GREEN}OK${CLR}"
    else
      echo -e "${RED}ERROR${CLR}\n\t$err"
    fi
  done
else
  echo "${RED}puppet not found.${CLR}"
fi

echo

if [ ! -z ${RUBY} ]; then
  echo "${YELLOW}Validating YAML.${CLR}"
  for i in $(find data -name "*.yaml")
  do
    echo -ne "$i - "
    err=$(${RUBY} -e "require 'yaml'; YAML.parse(File.open('$i'))" 2>&1)
    if [ $? = 0 ]; then
      echo "${GREEN}OK${CLR}"
    else
      echo -e "${RED}ERROR${CLR}\n\t$err"
    fi
  done
else
  echo "${RED}ruby not found.${CLR}"
fi

echo

if [ ! -z ${ERB} ] && [ ! -z ${RUBY} ]; then
  echo "${YELLOW}Validating ERB files.${CLR}"
  for i in $(find templates -name '*.erb')
  do
    echo -ne "$i - "
    err=$(${ERB} -x -T - "${i}" | ${RUBY} -c 2>&1)
    if [ $? = 0 ]; then
      echo "${GREEN}OK${CLR}"
    else
      echo -e "${RED}ERROR${CLR}\n\t$err"
    fi
  done
else
  echo "${RED}erb not found.${CLR}"
fi

echo

echo "${YELLOW}Checking whitespace and colon count in YAML files.${CLR}"
for i in $(find ../tinydata/data -name '*.yaml')
do
  echo -ne "$i - "
  err=$(cat "$i" | perl -e '$i=0; while($_ = <>) { $i++; if ( $_ !~ /^([ ]{2})+\S([^:]+(::\w+)*):\s+/ ) { $_ =~ s/^\s+//; print "line $i - $_"; } }' | grep ':' | grep -v '#')
  if [ $? = 1 ]; then
    echo "${GREEN}OK${CLR}"
  else
    echo -e "${RED}ERROR${CLR}\n$err"
  fi
done
