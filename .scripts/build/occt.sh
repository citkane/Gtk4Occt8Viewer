#!/usr/bin/bash

occt_configure() {
    local pack=$1
    local src_dir=$CLONE_DIR/$OCCT_VERSION
    local build_dir=$BUILD_DIR/$OCCT_VERSION
    local prefix=$PREFIX/$OCCT_VERSION
    local -a flags=("${@:2}")
    echo "flags: ${flags[@]}"
    local -a modules=()
    local options=(
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE
        -DBUILD_CPP_STANDARD=C++17
        -DBUILD_USE_VCPKG=OFF
        -DINSTALL_DIR_LAYOUT=Unix
        -DCMAKE_C_COMPILER_LAUNCHER=ccache
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
    )

    parse_options options "${flags[@]:-}"
    parse_modules modules "${flags[@]:-} Visualization ModelingAlgorithms"
    rm -f $src_dir/compile_commands.json

    export CFLAGS="-w"
    export CXXFLAGS="-w"
    occt_uninstall
    cmake --install-prefix $prefix -G Ninja \
        -S $src_dir -B $build_dir \
        "${options[@]}" \
        "${modules[@]}"

    cp $build_dir/compile_commands.json $src_dir/compile_commands.json
}

occt_build() {
    local build_dir=$BUILD_DIR/$OCCT_VERSION
    echo "Building OCCT to $build_dir"
    cmake --build $build_dir --parallel
}

occt_clone() {
    local src_dir=$CLONE_DIR/$OCCT_VERSION
    local url=https://github.com/Open-Cascade-SAS/OCCT.git
    [[ -e "$src_dir/CMakeLists.txt" ]] && return 0

    echo "Cloning OCCT to $src_dir"
    rm -rf "$src_dir"
    git clone -b $OCCT_VERSION --single-branch $url $src_dir
}

occt_install() {
    local build_dir=$BUILD_DIR/$OCCT_VERSION
    echo "Installing OCCT to $PREFIX/$OCCT_VERSION"
    print_same_line cmake --install $build_dir
}

occt_uninstall() {
    local build_dir=$BUILD_DIR/$OCCT_VERSION
    local manifest=$build_dir/install_manifest.txt
    [[ ! -e $manifest ]] && return 0

    uninstall_manifest "$manifest"
}

occt_clean() {
    local build_dir=$BUILD_DIR/$OCCT_VERSION
    cmake --build $build_dir --target clean
}

occt_delete() {
    local build_dir=$BUILD_DIR/$OCCT_VERSION
    occt_uninstall
    rm -rf $build_dir
}

parse_options() {
    local -n ref_options=$1
    local -a flags=("${@:2}")
    local gles=-DUSE_GLES2=OFF
    local gl=-DUSE_OPENGL=ON
    [[ "$OSTYPE" == linux* ]] && local x11=-DUSE_XLIB=ON

    for flag in ${flags[@]:-}; do
        case $flag in
        # If USE_OPENGL=ON and USE_GLES=ON co-exist, GTK4 fails
        # OCCT CMake does not automatically override these
        # @TODO create bug report
        gles) gles=-DUSE_GLES2=ON && gl=-DUSE_OPENGL=OFF ;;
        # In real world applications, Nix users can switch between Wayland and X11 sessions.
        # OCCT however limits itself to an EGL OR X11 path at compile time.
        # This neccesitates two different builds for the same OS, which is unsustainable.
        # @TODO work on PR to make EGL / X11 a runtime path decision for Nix
        wayland) x11=-DUSE_XLIB=OFF ;;
        esac
    done
    ref_options+=(${gles} ${gl} ${x11:-})
}

parse_modules() {
    local -n ref_modules=$1
    local -a flags=("${@:2}")
    local -a module_flags
    local vs=Visualization=OFF
    local ma=ModelingAlgorithms=OFF
    local fc=FoundationClasses=OFF
    local af=ApplicationFramework=OFF
    local de=DataExchange=OFF
    local d=Draw=OFF
    local md=ModelingData=OFF
    for flag in ${flags[@]:-}; do
        case $flag in
        Visualization) vs=Visualization=ON ;;
        ModelingAlgorithms) ma=ModelingAlgorithms=ON ;;
        FoundationClasses) fa=FoundationClasses=ON ;;
        ApplicationFramework) af=ApplicationFramework=ON ;;
        DataExchange) de=DataExchange=ON ;;
        Draw) d=Draw=ON ;;
        ModelingData) md=ModelingData=ON ;;
        esac
    done
    modules_flags+=($vs $ma $fc $af $de $d $md)
    for module in "${modules_flags[@]}"; do
        ref_modules+=("-DBUILD_MODULE_$module")
    done
}
