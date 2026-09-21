#!/usr/bin/bash

example_configure() (
	local build_dir=$1
	local prefix=$2

	mkdir -p $build_dir
	rm -f ./compile_commands.json

	cmake -S . -B $build_dir -G Ninja \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DCMAKE_INSTALL_PREFIX=$prefix

	cp $build_dir/compile_commands.json ./compile_commands.json
)
example_build() (
	local build_dir=$1
	cmake --build $build_dir --config Release --parallel 6
)

example_install() {
	local build_dir=$1
	cmake --install $build_dir
}

example_uninstall() {
	local build_dir=$1
	xargs rm -v <$build_dir/install_manifest.txt
}

example_clean() {
	local build_dir=$1
	rm -f ./compile_commands.json
	rm -rf $build_dir/peel-generated
	cmake --build $build_dir --target clean
}

example_delete() {
	local build_dir=$1
	example_uninstall $build_dir
	rm -rf $build_dir
}
