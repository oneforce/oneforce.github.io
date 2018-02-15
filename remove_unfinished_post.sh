#!/usr/bin/env bash

find source/ -type f -print0 |while read -d $'\0' file; do if grep -E '^finish(ed)?: *false$' "$file"; then echo $file": 未完成编写";rm --f $file; fi; done
