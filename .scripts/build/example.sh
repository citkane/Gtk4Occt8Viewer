#!/usr/bin/bash

example_configure() (
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    local options=(
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_BUILD_TYPE=$BUILD_TYPE
    )

    rm -f ./compile_commands.json
    example_uninstall $pack
    cmake --install-prefix $PREFIX -G Ninja \
        -S . -B $build_dir \
        "${options[@]}"

    cp $build_dir/compile_commands.json ./compile_commands.json
)
example_build() (
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    cmake --build $build_dir --config Release --parallel 6
)

example_install() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    cmake --install $build_dir
}

example_uninstall() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    local manifest="$build_dir/install_manifest.txt"
    [[ ! -e "$manifest" ]] && return 0

    uninstall_manifest "$manifest"
}

example_clean() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    rm -f ./compile_commands.json
    rm -rf $build_dir/peel-generated
    cmake --build $build_dir --target clean
}

example_delete() {
    local pack=$1
    local build_dir=$BUILD_DIR/$pack
    example_uninstall $pack
    rm -rf $build_dir
}
