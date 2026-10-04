#!/usr/bin/bash

USE_SYS=UCRT64
MESA_DIR="$CLONE_DIR/mesa-dist-win"
export GI_GIR_PATH=/${USE_SYS,,}/share/gir-1.0
export Python3_EXECUTABLE=/${USE_SYS,,}/bin/python.exe

PCKGS=(
    python
    gcc
    cmake
    meson
    gdb
    git
    ninja
    gtk4
    gobject-introspection
    freetype
    headers
    crt
    ccache
    toolchain
    angleproject
    7zip
)

install_os_dependencies() {
    list_dependencies dependencies "The following packages will be installed:"
    ((${#dependencies[@]} == 0)) && return 0

    pacman -Suy
    for dependency in ${dependencies[@]}; do
        if [[ $dependency == mesa-dist-win ]]; then
            win_download_mesa
        else
            pacman -S --needed $dependency
        fi
    done
}

win_list() {
    local -n pack_list=$1
    # provides pacboy - short package names instead of explicit long names
    pacman -S --needed pactoys
    mapfile -t pack_list < <(pacboy -T "${PCKGS[@]}")
    ! win_has_mesa && pack_list+=("mesa-dist-win")
}

win_use_mesa() {
    local softgl=$1
    local softgles=$2

    if [[ -n "${softgl:-}" || -n "${softgles:-}" ]]; then
        cp -n $MESA_DIR/x64/libgallium_wgl.dll $PREFIX/bin/libgallium_wgl.dll

        if [[ -n "$softgles" ]]; then
            cp -n $MESA_DIR/x64/libEGL.dll $PREFIX/bin/libEGL.dll
            cp -n $MESA_DIR/x64/libGLESv2.dll $PREFIX/bin/libGLESv2.dll
            rm -f $PREFIX/bin/opengl32.dll
        elif [[ -n "$softgl" ]]; then
            cp -n $MESA_DIR/x64/opengl32.dll $PREFIX/bin/opengl32.dll
            rm -f $PREFIX/bin/libEGL.dll
            rm -f $PREFIX/bin/libGLESv2.dll
        fi
    else
        rm -f $PREFIX/bin/opengl32.dll
        rm -f $PREFIX/bin/libgallium_wgl.dll
        rm -f $PREFIX/bin/libEGL.dll
        rm -f $PREFIX/bin/libGLESv2.dll
    fi
}

win_has_mesa() {
    if [[ ! -f $MESA_DIR/x64/libgallium_wgl.dll ]]; then
        rm -rf $MESA_DIR
        return 1
    else
        return 0
    fi
}

win_download_mesa() {
    local mesa_v=26.2.3
    local mesa_f=mesa3d-$mesa_v-release-mingw.7z
    local url="https://github.com/pal1000/mesa-dist-win/releases/download/$mesa_v/$mesa_f"

    wget -nv -P $MESA_DIR $url &&
        7z x $MESA_DIR/$mesa_f -o$MESA_DIR -ir!x64\* &&
        rm $MESA_DIR/$mesa_f
}

if [[ ! ${MSYSTEM:-} == $USE_SYS ]]; then
    echo "Please use a MSYS2 $USE_SYS shell"
    exit 1
fi
