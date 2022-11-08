#!/usr/bin/env bash
[[ -n "${PT_app}" ]] && app="${PT_app}"
tp version "${app}" 2>&1
