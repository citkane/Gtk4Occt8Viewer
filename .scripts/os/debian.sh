#!/usr/bin/bash

export GI_GIR_PATH=/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/gir-1.0
PCKGS=(
    python3
    build-essential
    gdb
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
    mesa-vulkan-drivers
    wayland-utils
    libfreetype-dev
)
install_os_dependencies() {
    local -a dependencies
    list_dependencies dependencies "The following packages will be installed:"
    if ((${#dependencies[@]} == 0)); then
        debian_mesa_version && return 0 || return 1
    fi

    confirm && (
        sudo apt update && sudo apt install "${dependencies[@]}"
        debian_mesa_version
    ) || return 0

}

debian_mesa_version() {
    local installed_v=$(dpkg-query -W -f='${Version}\n' libgl1-mesa-dri)
    local available_v=$(apt-cache madison libgl1-mesa-dri |
        awk -F'|' '{gsub(/ /,"",$2); print $2}' |
        sort -V |
        tail -n1)

    if dpkg --compare-versions "$installed_v" ge "$MIN_MESA_V"; then
        echo_mesa_success $installed_v
        return 0
    elif ! apt-cache policy | grep -q "${VERSION_CODENAME:-}-backports"; then
        echo_mesa_needed
        echo "The apt source ${VERSION_CODENAME:-}-backports is required"
        echo "Please enable the source and try again"
        return 1
    elif dpkg --compare-versions "$available_v" ge "$MIN_MESA_V"; then
        echo_mesa_needed
        echo "The following command needs to be run:"
        echo "sudo apt install -t ${VERSION_CODENAME:-}-backports mesa-utils libegl-mesa0 libgl1-mesa-dri"
        confirm && (
            sudo apt install -t ${VERSION_CODENAME:-}-backports mesa-utils libegl-mesa0 libgl1-mesa-dri
        ) || return 0
    else
        echo_mesa_fail "Debian ${VERSION_CODENAME:-}"
        return 1
    fi
}

debian_list() {
    local -n param=$1
    mapfile -t param < <(
        for package in "${PCKGS[@]}"; do
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
                grep -qF 'install ok installed' ||
                printf '%s\n' "$package"
        done
    )
}
