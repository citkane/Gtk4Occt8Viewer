#!/usr/bin/bash

OCCT_VERSION=OCCT-801
BUILD_DIR=$(pwd)/.build
CLONE_DIR=$(pwd)/.clone
PREFIX=$(pwd)/.local
ADD_PATHS="$PREFIX:$PREFIX/bin:$PREFIX/lib"
[[ $PATH != *"$ADD_PATHS"* ]] && export PATH="$ADD_PATHS:$PATH"

print_help() {
    clear
    [[ -n $1 ]] && echo -e "$1\n"
    echo "================================================================================"
    echo "GTK4 OCCT8 install helper script"
    echo "================================================================================"
    echo "q                                        - quit"
    echo "h                                        - print this"
    echo "c                                        - clear the console"
    echo "--------------------------------------------------------------------------------"
    echo "<install | clean | uninstall | delete> <package>"
    echo "Packages: (use one) (required)"
    echo "<occt>                                   - $OCCT_VERSION"
    echo "<peel>                                   - peel C++ for Gtk4"
    echo "<viewer>                                 - Gtk4 OCCT8 viewer widget"
    echo "<example>                                - Viewer widget example app"
    echo "--------------------------------------------------------------------------------"
    echo "Options specific to <install>:"
    echo "install dependencies                     - OS build dependencies (as root)"
    echo "install list                             - list required OS build dependencies"
    echo
    echo "<install> <package> is a complete clone, build and install cycle as needed."
    echo "All clones, builds and installs are local to the project directory:"
    echo $(pwd)
    echo
    echo "Here OCCT is built for development. (Do not use for production)"
    echo "By default, only <module> Visualization is built"
    echo "install occt <flags>"
    echo "Flags: (optional)"
    echo "<x11>                                    - build for X11 (Nix) (default)"
    echo "<wayland>                                - build for Wayland (Nix)"
    echo "<gles>                                   - build for GlEs on supported platforms"
    echo "<module>                                 - additional OCCT modules to build"
    echo
    echo "Additional OCCT modules:"
    echo "<ModelingAlgorithms>"
    echo "<FoundationClasses>"
    echo "<ApplicationFramework>"
    echo "<DataExchange>"
    echo "<Draw>"
    echo "<ModelingData>"
    echo "--------------------------------------------------------------------------------"
    echo "Runtime flags require the corresponding OCCT build flags"
    echo "run <flags>                              - Run the example app"
    echo "Flags: (optional)"
    echo "<debug>                                  - Run through the GNU Debugger"
    echo "<x11>                                    - Run as X11 (Wayland)"
    echo "<gles>                                   - Use GlEs (X11)"
    echo "================================================================================"
}

prompt() {
    printf '%s' "installer > "
}

run() {
    local command=(example_viewer)
    local -a gtk_env
    local -a x11
    local use_gles

    for flag; do
        case $flag in
        debug)
            command=(gdb example_viewer)
            gtk_env+=(GDK_SYNCHRONIZE=1 G_MESSAGES_DEBUG=all)
            ;;
        x11) x11+=(GDK_BACKEND=x11 GDK_DISABLE=egl) ;;
        gles) use_gles=USE_GLES=1 ;;
        esac
    done
    [[ -v 'x11[0]' && -v use_gles ]] && x11=(GDK_BACKEND=x11)
    [[ -v use_gles ]] && gtk_env+=($use_gles)
    [[ -v 'x11[0]' ]] && gtk_env+=("${x11[@]:-}")
    source env.sh # The OCCT env script - required
    if ((${#gtk_env[@]} > 0)); then
        env "${gtk_env[@]}" "${command[@]}"
    else
        "${command[@]}"
    fi
}

install() {
    local pack=$1
    local os
    local clone
    local build
    local configure
    local prepare
    local install
    local change_dir
    local stat

    for flag; do
        case $flag in
        cd) change_dir=".$pack" ;;
        clone) clone=($CLONE_DIR/$pack $OCCT_VERSION) ;;
        configure) configure=($BUILD_DIR/$pack $PREFIX) ;;
        prepare) prepare=($CLONE_DIR/$pack $BUILD_DIR/$pack $PREFIX ${args[@]:2}) ;;
        build) build=($BUILD_DIR/$pack) ;;
        build_meson) build=($BUILD_DIR/$pack $CLONE_DIR/$pack $PREFIX) ;;
        install) install=$BUILD_DIR/$pack ;;
        esac
    done
    (
        set -e
        [[ -n ${change_dir-} ]] && cd $change_dir
        [[ -n ${clone-} ]] && ${pack}_clone "${clone[@]}"
        [[ -n ${configure-} ]] && ${pack}_configure "${configure[@]}"
        [[ -n ${prepare-} ]] && ${pack}_prepare "${prepare[@]}"
        [[ -n ${build-} ]] && ${pack}_build "${build[@]}"
        [[ -n ${install-} ]] && ${pack}_install $install
    )
    stat=$?
    ((stat == 0)) && echo -e "\n$pack install successful" || echo -e "\n$pack install failed"
}

clean() {
    local pack=$1
    local stat
    (
        ${pack}_clean $BUILD_DIR/$pack
    )
    stat=$?
    ((stat == 0)) && echo -e "\n$pack clean successful" || echo -e "\n$pack clean failed"
}

delete() {
    local pack=$1
    local stat
    (
        ${pack}_delete $BUILD_DIR/$pack
    )
    stat=$?
    ((stat == 0)) && echo -e "\n$pack delete successful" || echo -e "\n$pack delete failed"
}

uninstall() {
    local pack=$1
    local stat
    (
        ${pack}_uninstall $BUILD_DIR/$pack
    )
    stat=$?
    ((stat == 0)) && echo -e "\n$pack uninstall successful" || echo -e "\n$pack uninstall failed"
}

confirm() {
    local answer
    printf '%s\nProceed? [y/N] ' "$1"
    read -r answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

print_help
source .scripts/install.sh || return 1
source .scripts/build.sh
prompt

while read -r -a args; do
    [[ -z "${args[0]-}" ]] && continue
    echo "Given command: ${args[@]}"

    case "${args[0]}" in
    q) clear && return 0 ;;
    h) print_help ;;
    c) clear ;;
    run) run "${args[@]}" ;;
    install)
        case "${args[1]}" in
        dependencies) install_os_dependencies ;;
        list) list_dependencies noop ;;
        viewer) install viewer configure build install ;;
        example) install example cd configure build install ;;
        peel) install peel clone build_meson install ;;
        occt) install occt clone prepare build install "${args[2]:-}" ;;
        *) print_help "Invalid install input" ;;
        esac
        ;;
    clean)
        case "${args[1]}" in
        viewer) clean viewer ;;
        example) clean example ;;
        peel) clean peel ;;
        occt) clean occt ;;
        *) print_help "Invalid clean input" ;;
        esac
        ;;
    delete)
        case "${args[1]}" in
        viewer) delete viewer ;;
        example) delete example ;;
        peel) delete peel ;;
        occt) delete occt ;;
        *) print_help "Invalid delete input" ;;
        esac
        ;;
    uninstall)
        case "${args[1]}" in
        viewer) uninstall viewer ;;
        example) uninstall example ;;
        occt) uninstall occt ;;
        peel) uninstall peel meson ;;
        *) print_help "Invalid uninstall input" ;;
        esac
        ;;
    *) print_help "Invalid input" ;;
    esac
    prompt
done
