#!/usr/bin/env bash
declare tp_options
PATH=$PATH:/usr/local/bin
[[ -n "${PT_app}" ]] && tp_options="${PT_app}"
tp test $tp_options
