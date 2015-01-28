#!/bin/bash

build_script_suffix=.carbuild
config_script_suffix=-config${build_script_suffix}

if [ "${V}" = "1" ]; then
	set -x
fi

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

function clean_inot_file {
	tmp_file=$(mktemp)
	sed 's# .* ##g' $1 | sort --unique | while read line; do
		if [ -e "${line}" ] || [ -h "${line}" ]; then
			echo ${line} >> ${tmp_file}
		fi
	done

	mv ${tmp_file} $1
}

function start_watching_installed_files {
	target=$1
	inot_file=$2

	tmp_file=$(mktemp)
	inotifywait --monitor --recursive \
		--event create,moved_to,modify ${STAGING_DIR} \
		--outfile ${inot_file} \
		> ${tmp_file} 2>&1 &

	inotify_pid=$!

	cat ${tmp_file} | while read line; do
		if [ "${line}" = "Watches established." ]; then
			break
		fi
	done
	rm ${tmp_file}

	echo ${inotify_pid}
}

function dirclean {
	target=$1

	if [[ ${target%-dirclean}  = *-config ]]; then
		echo "cannot dirclean a config target !"
		exit 1
	fi
	rm -rf ${BUILD_DIR}/${target}
	echo " *** removed build directory for ${target%-dirclean}"
}

function build_package {
	target=$1

	echo ' *** handling target "'${target}'"'
	cd ${BUILD_SCRIPTS_DIR}
	bs=${BUILD_SCRIPTS_DIR}/${target%-dirclean}${build_script_suffix}
	if [ ! -e "${bs}" ] && [ ! -h "${bs}" ]; then
		echo no build script named '"'${bs}'"'
		exit 1
	fi
	if [[ ${target}  = *-dirclean ]]; then
		dirclean ${target%-dirclean}
		continue
	fi

	# create build dir
	t=${target%-config}
	mkdir -p ${BUILD_DIR}/${target}

	inot_file=${BUILD_DIR}/${target}/${target}.staging_files
	inotify_pid=$(start_watching_installed_files ${target} \
		${inot_file})

	package_name=${target%.host}
	echo " *** executing build script \"${bs}\""
	if [[ ${target} = *.host ]]; then
		# use host toolchain for host tools build...
		PKG_CONFIG_PATH=${HOST_PKG_CONFIG_PATH} \
		CFLAGS=${HOST_CFLAGS} \
		CPPFLAGS=${HOST_CPPFLAGS} \
		LDFLAGS=${HOST_LDFLAGS} \
		CC="${CCACHE} gcc" \
		PACKAGE_NAME=${package_name} \
		PACKAGE_BUILD_DIR=${BUILD_DIR}/${target} \
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
	echo " *** ${bs} executed successfully"

	kill ${inotify_pid}
	inotify_pid=

	clean_inot_file ${inot_file}
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
for target in ${targets}; do
	build_package ${target}
done
merge_skel
