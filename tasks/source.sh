#!/usr/bin/env bash
PATH=$PATH:/usr/local/bin

[[ -n "${PT_app}" ]] && app="${PT_app}"
if [[ -n "${PT_url}" ]]; then
  tp source "${app}" "${PT_url}" "${PT_target}"  2>&1
else
  tp info "${app}" 2>&1
fi