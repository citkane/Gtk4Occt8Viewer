#!/usr/bin/bash

viewer_configure() (
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    local gles=$2
    [[ $gles == "gles" ]] && gles="-DUSE_GLES2=ON" || gles="-DUSE_GLES2=OFF"
    local options=(
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE
        $gles
    )
    rm -f ./compile_commands.json
    viewer_uninstall $pack
    cmake --install-prefix $PREFIX -G Ninja \
        -S . -B $build_dir \
        "${options[@]}"

    cp $build_dir/compile_commands.json ./compile_commands.json
)

viewer_build() (
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    echo "Building Gtk4Occt8Viewer to $build_dir"
    cmake --build $build_dir --parallel
)

viewer_clean() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    rm -f ./compile_commands.json
    rm -rf $build_dir/peel-generated
    cmake --build $build_dir --target clean
}

viewer_install() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    cmake --install $build_dir
}

viewer_uninstall() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    local manifest=$build_dir/install_manifest.txt
    [[ ! -e $manifest ]] && return 0

    uninstall_manifest "$manifest"
}

viewer_delete() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    viewer_uninstall $pack
    rm -rf $build_dir
}
