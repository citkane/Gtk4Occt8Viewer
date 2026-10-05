#!/usr/bin/bash

OCCT_VERSION=${OCCT_VERSION:-"OCCT-801"}
BUILD_DIR=${BUILD_DIR:-"$(pwd)/.build"}
CLONE_DIR=${CLONE_DIR:-"$(pwd)/.clone"}
PREFIX=${PREFIX:-"$(pwd)/.local"}
BUILD_TYPE=${BUILD_TYPE:-"Debug"}

[[ "$OSTYPE" == linux* ]] && IS_LINUX=true || IS_LINUX=false
[[ "$OSTYPE" == darwin* ]] && IS_MAC=true || IS_MAC=false
[[ "$OSTYPE" == cygwin* || "$OSTYPE" == win32* ]] && IS_WINDOWS=true || IS_WINDOWS=false

DEV_PATHS=("$PREFIX" "$PREFIX/bin" "$PREFIX/lib")
for path in ${DEV_PATHS[@]}; do
    [[ $PATH == *"$path"* ]] && continue
    export PATH="$path:$PATH"
done

print_help() {
    clear
    [[ -n $1 ]] && echo -e "$1\n"
    echo "================================================================================"
    echo "GTK4 OCCT8 install helper script"
    echo "================================================================================"
    echo "q                                        - quit"
    echo "h                                        - print this"
    echo "c                                        - clear the console"
    echo "CC                                       - clear ccache"
    echo "nuke                                     - ensure a fresh build environment"
    echo
    echo "<install|clean|uninstall|delete> <package> (use one) (required) ----------------"
    echo "[install] <package> is a complete clone, build and install cycle as needed."
    echo "All clones, builds and installs are local to the project directory:"
    echo $(pwd)
    echo "--------------------------------------------------------------------------------"
    echo "<occt>                                   - $OCCT_VERSION"
    echo "<peel>                                   - peel C++ for Gtk4"
    echo "<viewer>                                 - Gtk4 OCCT8 viewer widget"
    echo "<example>                                - Viewer widget example app"
    echo
    echo "[install] <options> (use one) --------------------------------------------------"
    echo "--------------------------------------------------------------------------------"
    echo "dependencies                             - OS build dependencies (as root)"
    echo "list                                     - list required OS build dependencies"
    echo
    echo "[install] [occt] <flags> (optional) --------------------------------------------"
    echo "OCCT is built for development. (Do not use for production)"
    echo "--------------------------------------------------------------------------------"
    echo "<x11>                                    - build for X11 (Nix) (default)"
    echo "<wayland>                                - build for Wayland (Nix)"
    echo "<gles>                                   - build for GlEs on supported platforms"
    echo "<module>                                 - additional OCCT modules to build"
    echo
    echo "[install] [occt] <flags|modules> (optional) ------------------------------------"
    echo "By default Visualization and ModelingAlogorithms is built"
    echo "--------------------------------------------------------------------------------"
    echo "<Visualization>"
    echo "<ModelingAlgorithms>"
    echo "<ModelingData>"
    echo "<FoundationClasses>"
    echo "<ApplicationFramework>"
    echo "<DataExchange>"
    echo "<Draw>"
    echo
    echo "[install] [viewer] <flags> (optional) --------------------------------------------"
    echo "--------------------------------------------------------------------------------"
    echo "<gles>                                   - build for GlEs on supported platforms"
    echo
    echo "[run] <flags> (optional) -------------------------------------------------------"
    echo "Runs the example application"
    echo "Flags may require a corresponding OCCT build"
    echo "--------------------------------------------------------------------------------"
    echo "<debug>                                  - Run through the GNU Debugger"
    echo "<x11>                                    - Run as X11 (Wayland)"
    echo "<softgles>                               - Use software GLES render (Windows)"
    echo "<softgl>                                 - Use software GL render (Windows)"
    echo
    echo "================================================================================"
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
    local softgl
    local softgles

    # Resolve the given args to a list of environment variables
    for flag; do
        case $flag in
        debug)
            command=(gdb example_viewer)
            gtk_env+=(GDK_SYNCHRONIZE=1 G_MESSAGES_DEBUG=all)
            ;;
        x11) x11+=(GDK_BACKEND=x11 GDK_DISABLE=egl) ;;
        softgl) $IS_WINDOWS && softgl=GALLIUM_DRIVER=llvmpipe ;;
        softgles) $IS_WINDOWS && softgles=GALLIUM_DRIVER=llvmpipe ;;
        esac
    done
    ((${#x11[@]} > 0)) && gtk_env+=("${x11[@]}")
    [[ -v softgl ]] && gtk_env+=($softgl)
    [[ -v softgles ]] && gtk_env+=($softgles)

    # Run the executeable in a new process scope to preserve the parent shell env
    (
        ((${#gtk_env[@]} > 0)) && export "${gtk_env[@]}"
        if $IS_WINDOWS; then
            # Windows on VM is rarely hardware accelerated, so wgl will not be not useable.
            # We switch to llvmpipe software rendering if flagged.
            win_use_mesa ${softgl:-""} ${softgles:-""}
            "$COMSPEC" //c "call env.bat && ${command[@]}"
        else
            source env.sh
            "${command[@]}"
        fi
    )
}

install() {
    local pack=$1
    local os
    local clone
    local build
    local -a configure
    local install
    local change_dir
    local stat
    local use_gles

    for flag; do
        case $flag in
        cd) change_dir=".$pack" ;;
        clone) clone=($CLONE_DIR/$pack $OCCT_VERSION) ;;
        configure) configure+=($BUILD_DIR/$pack $PREFIX) ;;
        gles) use_gles=-DUSE_GLES=ON ;;
        prepare) configure+=($CLONE_DIR/$pack $BUILD_DIR/$pack $PREFIX ${args[@]:2}) ;;
        build) build=($BUILD_DIR/$pack) ;;
        build_meson) build=($BUILD_DIR/$pack $CLONE_DIR/$pack $PREFIX) ;;
        install) install=$BUILD_DIR/$pack ;;
        esac
    done
    configure+=(${use_gles:-})
    (
        set -e
        [[ -n ${change_dir-} ]] && cd $change_dir
        [[ -n ${clone-} ]] && ${pack}_clone "${clone[@]}"
        [[ -n ${configure-} ]] && ${pack}_configure "${configure[@]}"
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

nuke() {
    rm -rf $PREFIX
    rm -rf $CLONE_DIR
    rm -rf $BUILD_DIR
    ccache -C
    $IS_WINDOWS && win_download_mesa
}

print_help
source .scripts/install.sh
source .scripts/build.sh
prompt

while read -r -a args; do
    [[ -z "${args[0]-}" ]] && continue
    echo "Given command: ${args[@]}"

    case "${args[0]}" in
    q) clear && return 0 ;;
    h) print_help ;;
    c) clear ;;
    CC) ccache -C ;;
    nuke) nuke ;;
    sys) echo ${MSYSTEM:-${DISTRO:-${OSTYPE}}} ;;
    run) run "${args[@]}" ;;
    install)
        case "${args[1]}" in
        dependencies) install_os_dependencies ;;
        list) list_dependencies noop ;;
        viewer) install viewer configure build install "${args[2]:-}" ;;
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
