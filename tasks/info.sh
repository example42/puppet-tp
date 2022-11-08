#!/usr/bin/env bash
PATH=$PATH:/usr/local/bin

[[ -n "${PT_app}" ]] && app="${PT_app}"
if [[ -n "${PT_block}" ]]; then
  tp info "${app}" "${PT_block}"  2>&1
else
  tp info "${app}" 2>&1
fi