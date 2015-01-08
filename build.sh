#!/bin/bash

set -x

. config/build_config

function create_tree_structure {
	mkdir -p ${OUT_DIR}
	mkdir -p ${BUILD_DIR}
	mkdir -p ${STAGING_DIR}
	mkdir -p ${FINAL_DIR}
	mkdir -p ${BOOT_DIR}
	mkdir -p ${UBOOT_DIR}
}

function set_environment {
	export OUT_DIR
	export BUILD_DIR
	export STAGING_DIR
	export FINAL_DIR
	export BOOT_DIR
	export UBOOT_DIR

	export CONFIG_DIR
	export PACKAGES_DIR
	export BUILD_SCRIPTS_DIR

	export TOOLCHAIN_PREFIX
}

function build_packages {
	build_scripts=$(find -name '*.carbuild.sh' | sort)

	for bs in ${build_scripts}; do
		echo executing build script '"'${bs}'"'
		. ${bs}
	done
}

create_tree_structure
set_environment
build_packages
