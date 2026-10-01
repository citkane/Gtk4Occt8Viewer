#!/usr/bin/bash

viewer_configure() (
    local build_dir=$1
    local prefix=$2
    local use_gles=$3
    local d_opts=(
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_INSTALL_PREFIX=$prefix
        ${use_gles:-"-DUSE_GLES=OFF"}
    )
    mkdir -p $build_dir
    rm -f ./compile_commands.json
    cmake -S . -B $build_dir -G Ninja "${d_opts[@]}"
    cp $build_dir/compile_commands.json ./compile_commands.json
)

viewer_build() (
    local build_dir=$1

    cmake --build $build_dir --config Release --parallel 6
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
    uninstall_manifest "$build_dir"
}

viewer_delete() {
    local build_dir=$1
    viewer_uninstall $build_dir
    rm -rf $build_dir
}
