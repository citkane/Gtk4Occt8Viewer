#!/usr/bin/bash

viewer_configure() (
    local build_dir=$1
    local prefix=$2
    local use_gles=$3
    local options=(
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE
        ${use_gles:-"-DUSE_GLES=OFF"}
    )
    rm -f ./compile_commands.json
    viewer_uninstall $build_dir
    cmake --install-prefix $prefix -G Ninja \
        -S . -B $build_dir \
        "${options[@]}"

    cp $build_dir/compile_commands.json ./compile_commands.json
)

viewer_build() (
    local build_dir=$1
    echo "Building Gtk4Occt8Viewer to $build_dir"
    cmake --build $build_dir --parallel
)

viewer_clean() {
    local build_dir=$1
    rm -f ./compile_commands.json
    rm -rf $build_dir/peel-generated
    cmake --build $build_dir --target clean
}

viewer_install() {
    local build_dir=$1
    cmake --install $build_dir
}

viewer_uninstall() {
    local build_dir=$1
    local manifest=$build_dir/install_manifest.txt
    [[ ! -e $manifest ]] && return 0

    uninstall_manifest "$manifest"
}

viewer_delete() {
    local build_dir=$1
    viewer_uninstall $build_dir
    rm -rf $build_dir
}
