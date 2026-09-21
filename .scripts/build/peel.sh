#!/usr/bin/bash

peel_build() (
	local build_dir=$1
	local src_dir=$2
	local prefix=$3

	rm -rf $build_dir
	meson setup --prefix=$prefix --buildtype=plain $build_dir $src_dir
	meson compile -C $build_dir
)

peel_clone() {
	local src_dir=$1
	[[ -d "$src_dir" ]] || git clone https://gitlab.gnome.org/bugaevc/peel $src_dir
}

peel_install() {
	local build_dir=$1
	meson install -C $build_dir
}

peel_uninstall() {
	local build_dir=$1
	(
		cd $build_dir
		ninja uninstall
	)
}

peel_clean() {
	local build_dir=$1
	rm -rf $build_dir
}

peel_delete() {
	peel_uninstall $build_dir
	peel_clean $1
}
