#!/usr/bin/bash

occt_prepare() {
    local src_dir=$1
    local build_dir=$2
    local prefix=$3
    local -a flags=("${@:4}")
    local options=(
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_C_COMPILER_LAUNCHER=ccache
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DBUILD_CPP_STANDARD=C++17
        -DBUILD_USE_VCPKG=OFF
    )
    local modules=(-DBUILD_MODULE_Visualization=ON)

    parse_options options "${flags[@]:-}"
    parse_modules modules "${flags[@]:-}"

    export CFLAGS="-w"
    export CXXFLAGS="-w"
    cmake --install-prefix $prefix -G Ninja \
        -S $src_dir -B $build_dir \
        "${options[@]}" \
        "${modules[@]}"
}

occt_build() {
    local build_dir=$1
    cmake --build $build_dir --parallel
}

occt_clone() {
    local src_dir=$1
    local version=$2
    local url=https://github.com/Open-Cascade-SAS/OCCT.git

    [[ -d "$src_dir" ]] || git clone -b $version --single-branch $url $src_dir
}

occt_install() {
    local build_dir=$1
    occt_uninstall $build_dir silent
    cmake --install $build_dir
    echo
    echo "You may need to re-install viewer and example after re-building OCCT"
}

occt_uninstall() {
    local build_dir=$1
    local silent=$2
    local manifest=$build_dir/install_manifest.txt
    [[ ! -e $manifest ]] && return 0

    if [[ -n "$silent" ]]; then
        xargs rm -v <$manifest >/dev/null || return 0
    else
        xargs rm -v <$manifest
    fi
}
occt_clean() {
    local build_dir=$1
    cmake --build $build_dir --target clean
}

occt_delete() {
    local build_dir=$1
    occt_uninstall $build_dir
    rm -rf $build_dir
}

parse_options() {
    local -n ref_options=$1
    local -a flags=("${@:2}")
    local x11="-DUSE_XLIB=ON"
    local -a gles
    for flag in ${flags[@]:-}; do
        case $flag in
        # If USE_OPENGL=ON and USE_GLES=ON co-exist, GTK4 fails
        # OCCT CMake does not automatically override these
        # @TODO create bug report
        # gles) gles+=("-DUSE_GLES2=ON") ;;
        gles) gles+=("-DUSE_GLES2=ON" "-DUSE_OPENGL=OFF") ;;
        # In real world applications, Nix users can switch between Wayland and X11 sessions.
        # OCCT however limits itself to an EGL OR X11 path at compile time.
        # This neccesitates two different builds for the same OS, which is unsustainable.
        # @TODO work on PR to make EGL / X11 a runtime path decision for Nix
        wayland) x11=-DUSE_XLIB=OFF ;;
        esac
    done
    ref_options+=(${x11:-} ${gles[@]:-})
}

parse_modules() {
    local -n ref_modules=$1
    local -a flags=("${@:2}")
    local -a module_flags
    local ma=ModelingAlgorithms=OFF
    local fc=FoundationClasses=OFF
    local af=ApplicationFramework=OFF
    local de=DataExchange=OFF
    local d=Draw=OFF
    local md=ModelingData=OFF
    for flag in ${flags[@]:-}; do
        case $flag in
        ModelingAlgorithms) ma=ModelingAlgorithms=ON ;;
        FoundationClasses) fa=FoundationClasses=ON ;;
        ApplicationFramework) af=ApplicationFramework=ON ;;
        DataExchange) de=DataExchange=ON ;;
        Draw) d=Draw=ON ;;
        ModelingData) md=ModelingData=ON ;;
        esac
    done
    modules_flags+=($ma $fc $af $de $d $md)
    for module in "${modules_flags[@]}"; do
        ref_modules+=("-DBUILD_MODULE_$module")
    done
}
