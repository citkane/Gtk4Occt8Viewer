#!/usr/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
export CCACHE_SLOPPINESS=pch_defines,time_macros

uninstall_manifest() {
    local manifest=$1
    local -a paths
    local paths_string

    echo "Uninstalling from $manifest"
    while IFS= read -r path; do
        path=${path%$'\r'}
        [[ ! -e $path ]] && continue
        paths+=("$path")
    done <"$manifest"
    ((${#paths[@]})) || return 0

    printf '%s\0' "${paths[@]}" |
        print_same_line xargs -0 rm -v --
}

print_same_line() {
    local status
    set -o pipefail
    "$@" 2>&1 |
        while IFS= read -r line; do
            printf '\r\033[2K%s' "$line"
        done
    status=${PIPESTATUS[0]}
    printf '\n'
    return "$status"
}

source $THIS_DIR/build/viewer.sh
source $THIS_DIR/build/occt.sh
source $THIS_DIR/build/peel.sh
source $THIS_DIR/build/example.sh
