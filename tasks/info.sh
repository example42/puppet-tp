#!/usr/bin/env bash
declare tp_options
PATH=$PATH:/usr/local/bin
[[ -n "${PT_app}" ]] && app="${PT_app}"
[[ -n "${PT_block}" ]] && block="${PT_block}"
tp info "${app}" "${block}"
