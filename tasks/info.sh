#!/usr/bin/env bash
PATH=$PATH:/usr/local/bin
[[ -n "${PT_app}" ]] && app="${PT_app}"
[[ -n "${PT_block}" ]] && block="${PT_block}"
tp info "${app}" "${block}"
