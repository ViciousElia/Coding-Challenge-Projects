#!/bin/sh
printf '\033c\033]0;%s\a' Mines Maybe
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Mines Maybe.x86_64" "$@"
