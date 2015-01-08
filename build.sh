#!/bin/bash

build_script_suffix=.carbuild.sh
config_script_suffix=-config${build_script_suffix}
config_script_suffix_length=19

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
	for bs in ${build_scripts}; do
		# skip configuration build scripts, i.e. ending with -config.carbuild.sh
		if [ "${bs: -${config_script_suffix_length}}" = "${config_script_suffix}" ]; then
			continue
		fi

		echo executing build script '"'${bs}'"'
		. ${bs}
	done
}

if [ $# != 0 ]; then
	for t in $*; do
		build_scripts="${build_scripts} ${BUILD_SCRIPTS_DIR}/${t}${build_script_suffix}"
	done
else
	build_scripts=$(find ${BUILD_SCRIPTS_DIR} -name "*${build_script_suffix}" | sort)
fi

create_tree_structure
set_environment
build_packages
