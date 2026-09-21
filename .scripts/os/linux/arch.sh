#!/usr/bin/bash

PCKGS=(
    python
    cmake
    meson
    git
    ninja
    ccache
    gtk4
    gobject-introspection
    libglvnd
    mesa
    mesa-utils
    freetype2
)
install_os_dependencies() {
    local -a dependencies
    list_dependencies dependencies "The following packages will be installed:"
    ((${#dependencies[@]} == 0)) && return 0

    confirm && sudo pacman -S "${dependencies[@]}" || return 0
}

arch_list() {
    local -n param=$1
    mapfile -t param < <(pacman -T "${PCKGS[@]}")
}
