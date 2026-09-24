#!/usr/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
DISTRO=
MIN_MESA_V=

source_os() {
    if [[ "$OSTYPE" == linux* ]]; then
        MIN_MESA_V=25.2
        source /etc/os-release
        DISTRO="${ID_LIKE:-$ID}"

        if [[ ! -f "$THIS_DIR/os/$DISTRO.sh" ]]; then
            todo "Linux $DISTRO"
            return 1
        fi
        source "$THIS_DIR/os/$DISTRO.sh"

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
    local message=$2
    ${DISTRO}_list results

    if ((${#results[@]} == 0)); then
        echo "All OS dependencies are installed"
    else
        [[ -n $message ]] && echo $message
        echo
        printf '%s\n' "${results[@]}"
        echo
    fi
    [[ "$OSTYPE" == linux* ]] && [[ "$DISTRO" != "arch" ]] &&
        echo_mesa_needed &&
        [[ ! -n $message ]] &&
        echo "Please check your version, or run the install script to have it checked for you."
}

echo_mesa_needed() {
    echo "For Wayland EGL off-screen rendering on OCCT, Mesa >= $MIN_MESA_V is required."
}
echo_mesa_success() {
    local installed_v=$1
    echo "Has mesa $installed_v >= v$MIN_MESA_V"
}
echo_mesa_fail() {
    local system=$1
    echo "Required mesa version >= $MIN_MESA_V not available for $system."
    echo "Wayland rendering will not work on this system, please use X11 instead."
}

source_os
# source $THIS_DIR/install/dependencies.sh
