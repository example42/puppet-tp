#!/usr/bin/env bash
declare app
PATH=$PATH:/usr/local/bin
[[ -n "${PT_app}" ]] && app="${PT_app}"
tp test "${app}"
