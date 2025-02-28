#!/usr/bin/env bash

echo "script=$0"
echo "N=$#"
echo "args=\"$@\""

[[ "$0" == *bash ]] && echo "curl|bash"
echo "last=\"$(history | tail -n 1)\""

i=0
for arg in "$@"; do
    echo "arg[$1]=$arg"
    ((i++))
done
