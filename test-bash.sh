#!/usr/bin/env bash

echo "script=$0"
echo "N=$#"
echo "args=\"$@\""

i=0
for arg in "$@"; do
    echo "arg[$1]=$arg"
    ((i++))
done
