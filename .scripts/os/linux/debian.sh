#!/usr/bin/bash

export GI_GIR_PATH=/usr/lib/x86_64-linux-gnu/gir-1.0

PCKGS=(
    python3
    build-essential
    cmake
    meson
    git
    ninja-build
    ccache
    libgtk-4-dev
    gobject-introspection
    libglvnd-dev
    mesa-common-dev
    mesa-utils
    libfreetype-dev
)
install_os_dependencies() {
    local -a dependencies
    list_dependencies dependencies "The following packages will be installed:"
    ((${#dependencies[@]} == 0)) && return 0

    confirm && (
        sudo apt update && sudo apt install "${dependencies[@]}"
    ) || return 0
}

debian_list() {
    local -n param=$1
    # mapfile -t param < <(pacman -T "${PCKGS[@]}")
    mapfile -t param < <(
        for package in "${PCKGS[@]}"; do
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
                grep -qF 'install ok installed' ||
                printf '%s\n' "$package"
        done
    )
}
