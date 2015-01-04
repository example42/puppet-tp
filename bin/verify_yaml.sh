#!/bin/bash

basedir=`dirname $0`
datadir="$basedir/../data"

for i in `find $datadir -type f -name *.yaml`; do
    echo $i
    ruby -e "require 'yaml'; YAML.parse(File.open('$i'))"
done
