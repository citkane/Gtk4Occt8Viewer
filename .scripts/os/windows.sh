#!/usr/bin/bash

MSYS2_DIR=
HAS_CHILD_PROC=0
IS_CHILD_PROC=$0
USE_SYS=UCRT64
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
    ccache
    gtk4
    gobject-introspection
    freetype
    headers
    crt
)
PCKGS_PM=(
    mingw-w64-ucrt-x86_64-toolchain
    mingw-w64-ucrt-x86_64-angleproject
    mingw-w64-ucrt-x86_64-7zip
)

install_os_dependencies() {
    list_dependencies dependencies "The following packages will be installed:"
    ((${#dependencies[@]} == 0)) && return 0

    local -a p_man
    local -a p_boy
    pacman -Suy
    mapfile -t p_man < <(pacman -T "${PCKGS_PM[@]}")
    ((${#p_man[@]} > 0)) && pacman -S --needed "${p_man[@]}"
    mapfile -t p_boy < <(pacboy -T "${PCKGS[@]}")
    ((${#p_boy[@]} > 0)) && pacboy -S --needed "${p_boy[@]}"
}

win_list() {
    local -n pack_list=$1
    local i=0
    # provides pacboy - short package names instead of explicit long names
    pacman -S --needed pactoys
    mapfile -t pack_list < <(pacboy -T "${PCKGS[@]}")
    i=${#pack_list[@]}
    mapfile -O $i -t pack_list < <(pacman -T "${PCKGS_PM[@]}")
}

win_locate_msys2() {
    local dir_loc
    local home_drive=${HOMEDRIVE:-c}
    home_drive=${home_drive,,}
    home_drive=${home_drive%:}

    MSYS2_DIR=$(win_find_msys2_shell $home_drive)
    [[ -n "$MSYS2_DIR" ]] && return 0

    for drive in {a..z}; do
        [[ $drive==$home_drive ]] && continue

        MSYS2_DIR=$(win_find_msys2_shell $drive)
        [[ -n "$MSYS2_DIR" ]] && break
    done

    [[ -n "${MSYS2_DIR}" ]] && return 0 || return 1
}

win_find_msys2_shell() {
    local drive=$1
    local shell_cmd="msys2_shell.cmd"
    local file_path
    [[ -f "/$shell_cmd" ]] &&
        echo $(dirname $(cygpath -m "/$shell_cmd")) && return 0

    file_path=$(find /$drive -maxdepth 3 -type f -iname $shell_cmd -print 2>/dev/null)
    [[ ! -n "${file_path:-}" ]] && return 1

    echo $(dirname "$file_path")
}

win_use_mesa() {
    ! [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]] && return 0

    local softgl=$1
    local softgles=$2
    local dl_dir="$CLONE_DIR/mesa-dist-win"

    if [[ -n "$softgl" || -n "$softgles" ]]; then
        [[ ! -d $dl_dir ]] && download_mesa $dl_dir
        cp -n $dl_dir/x64/libgallium_wgl.dll $PREFIX/bin/libgallium_wgl.dll

        if [[ -n "$softgles" ]]; then
            cp -n $dl_dir/x64/libEGL.dll $PREFIX/bin/libEGL.dll
            cp -n $dl_dir/x64/libGLESv2.dll $PREFIX/bin/libGLESv2.dll
            rm -f $PREFIX/bin/opengl32.dll
        elif [[ -n "$softgl" ]]; then
            cp -n $dl_dir/x64/opengl32.dll $PREFIX/bin/opengl32.dll
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

download_mesa() {
    local dl_dir=$1
    local mesa_v=26.2.3
    local mesa_f=mesa3d-$mesa_v-release-mingw.7z
    wget -nv -P $dl_dir \
        https://github.com/pal1000/mesa-dist-win/releases/download/$mesa_v/$mesa_f &&
        7z x $dl_dir/$mesa_f -o$dl_dir -ir!x64\* &&
        rm $dl_dir/$mesa_f
}
if [[ ! ${MSYSTEM:-} == $USE_SYS ]]; then
    echo "Finding MSYS2 directory"
    ! win_locate_msys2 && return 1

    local env="$MSYS2_DIR/usr/bin/env"
    local bash="$MSYS2_DIR/usr/bin/bash"
    HAS_CHILD_PROC=1

    echo "Found $MSYS2_DIR, switching to $USE_SYS"
    "$env" CHERE_INVOKING=1 MSYSTEM=$USE_SYS \
        "$bash" -lc 'source installer.sh 1'
else
    [[ ! ${MSYSTEM:-} == $USE_SYS ]] && return 1
    [[ ${IS_CHILD_PROC:-} == 1 ]] && echo "Switched to MSYS2 $USE_SYS"
fi
