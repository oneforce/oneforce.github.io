find source/ -type f -name "*.md" -print0|xargs -0 grep  -E '^finish(ed)?: *false$'  | awk -F ":" '{print $1}'|  sed 's/ /\\ /g'| xargs rm
