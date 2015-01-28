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
	mkdir -p ${STAGING_HOST_DIR}
	mkdir -p ${FINAL_DIR}
	mkdir -p ${BOOT_DIR}
	mkdir -p ${U_BOOT_DIR}
	mkdir -p ${PKG_CONFIG_PATH}
}

function set_environment {
	export OUT_DIR
	export BUILD_DIR
	export STAGING_DIR
	export STAGING_HOST_DIR
	export FINAL_DIR
	export BOOT_DIR
	export U_BOOT_DIR
	export PKG_CONFIG_PATH

	export CONFIG_DIR
	export PACKAGES_DIR
	export BUILD_SCRIPTS_DIR

	export TOOLCHAIN_PREFIX
	export LIBC_DIR

	export PATH
}

function build_packages {
	for t in ${targets}; do
		bs=${BUILD_SCRIPTS_DIR}/${t}${build_script_suffix}
		# create build dir
		t=${t%-config}
		mkdir -p ${BUILD_DIR}/${t}

		package_name=${t%.host}
		echo executing build script '"'${bs}'"'
		if [[ ${t} = *.host ]]; then
			# use host toolchain for host tools build...
			PKG_CONFIG_PATH=${HOST_PKG_CONFIG_PATH} \
			CFLAGS=${HOST_CFLAGS} \
			CPPFLAGS=${HOST_CPPFLAGS} \
			LDFLAGS=${HOST_LDFLAGS} \
			CC="ccache gcc" \
			PACKAGE_NAME=${package_name} \
			PACKAGE_BUILD_DIR=${BUILD_DIR}/${t} \
					. ${bs} 2>&1 | \
					/usr/share/colormake/colormake.pl
			test ${PIPESTATUS[0]} -eq 0 # fail on build error
		else
			# .. and cross toolchain for target build
			CFLAGS=${CROSS_CFLAGS} \
			CPPFLAGS=${CROSS_CPPFLAGS} \
			LDFLAGS=${CROSS_LDFLAGS} \
			AS=${CROSS_AS} \
			CC=${CROSS_CC} \
			PACKAGE_NAME=${package_name} \
			PACKAGE_BUILD_DIR=${BUILD_DIR}/${package_name} \
					. ${bs} 2>&1 | \
					/usr/share/colormake/colormake.pl
			test ${PIPESTATUS[0]} -eq 0 # fail on build error
		fi
		echo "${bs} executed successfully"
	done
}

function merge_skel {
	cp -rpf ${CONFIG_DIR}/skel/* ${FINAL_DIR}
	find ${FINAL_DIR} -name .gitignore -exec rm {} \;
}

if [ $# != 0 ]; then
	targets=$*
else
	targets=$(cat ${CONFIG_DIR}/packages)
fi

create_tree_structure
set_environment
build_packages
merge_skel
