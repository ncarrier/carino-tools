#!/bin/bash

build_script_suffix=.carbuild
config_script_suffix=-config${build_script_suffix}

set -x
set -e

. config/build_config

function create_tree_structure {
	mkdir -p ${OUT_DIR}
	mkdir -p ${BUILD_DIR}
	mkdir -p ${STAGING_DIR}
	mkdir -p ${FINAL_DIR}
	mkdir -p ${BOOT_DIR}
	mkdir -p ${U_BOOT_DIR}
}

function set_environment {
	export OUT_DIR
	export BUILD_DIR
	export STAGING_DIR
	export FINAL_DIR
	export BOOT_DIR
	export U_BOOT_DIR

	export CONFIG_DIR
	export PACKAGES_DIR
	export BUILD_SCRIPTS_DIR

	export TOOLCHAIN_PREFIX
}

function build_packages {
	for bs in ${build_scripts}; do
		if [ "${manual_targets}" = "false" ] &&
				[[ ${bs} = *${config_script_suffix} ]];
		then
			echo skipping config build script when no explicit \
				target is specified
			continue
		fi

		echo executing build script '"'${bs}'"'
		. ${bs}
	done
}

function merge_skel {
	cp -rpf ${CONFIG_DIR}/skel/* ${FINAL_DIR}
	find ${FINAL_DIR} -name .gitignore -exec rm {} \;
}

if [ $# != 0 ]; then
	manual_targets="true"
	targets=($*)
else
	manual_targets="false"
	targets=($(cat ${CONFIG_DIR}/packages))
fi

targets=(${targets[@]/#/${BUILD_SCRIPTS_DIR}/}) # pre-pend build scripts dir
targets=${targets[@]/%/${build_script_suffix}} # append script suffix

create_tree_structure
set_environment
build_packages
merge_skel
