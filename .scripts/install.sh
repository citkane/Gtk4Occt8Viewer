#!/usr/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
DISTRO=

source_os() {
    if [[ "$OSTYPE" == linux* ]]; then
        source /etc/os-release
        DISTRO="${ID_LIKE:-$ID}"
        if [[ ! -f "$THIS_DIR/os/linux/$DISTRO.sh" ]]; then
            todo "Linux $distro"
            return 1
        fi
        source "$THIS_DIR/os/linux/$DISTRO.sh"

    elif [[ "$OSTYPE" == darwin* ]]; then
        todo "MacOS"
        return 1

    elif [[ "$OSTYPE" == msys* ]]; then
        todo "Windows msys2"
        return 1
    elif [[ "$OSTYPE" == cygwin* || "$OSTYPE" == win32* ]]; then
        echo "$OSTYPE is not supported. Please use msys2 for Windows"
        return 1
    else
        echo "Unsupported platform: $OSTYPE"
        contribute
        return 1
    fi
}
todo() {
    echo "$1 build script is on the TODO list..."
    contribute
}
contribute() {
    echo "Please contribute!"
    echo "Goodbye"
    echo
}
list_dependencies() {
    local -n results=$1
    ${DISTRO}_list results

    echo
    if ((${#results[@]} == 0)); then
        echo "All OS dependencies are installed"
        echo
        return 0
    fi
    [[ -n $2 ]] && echo $2
    printf '%s\n' "${results[@]}"
    echo
}

source_os
# source $THIS_DIR/install/dependencies.sh
