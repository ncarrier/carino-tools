#!/bin/bash

if [ "${V}" = "1" ]; then
	set -x
fi

build_script_suffix=.build
config_script_suffix=-config${build_script_suffix}

set -e

. config/build_config

function on_exit {
	if [ -n "${staging_inotify_pid}" ]; then
		kill -9 ${staging_inotify_pid}
	fi
	if [ -n "${final_inotify_pid}" ]; then
		kill -9 ${final_inotify_pid}
	fi
}

function create_tree_structure {
	mkdir -p ${OUT_DIR}
	mkdir -p ${BUILD_DIR}
	mkdir -p ${STAGING_DIR}
	mkdir -p ${STAGING_HOST_DIR}
	mkdir -p ${FINAL_DIR}
	mkdir -p ${BOOT_DIR}
	mkdir -p ${U_BOOT_DIR}
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
	watched_dir=$3

	tmp_file=$(mktemp)
	inotifywait --monitor --recursive \
		--event create,moved_to,modify ${watched_dir} \
		--outfile ${inot_file} \
		> ${tmp_file} 2>&1 &

	pid=$!

	cat ${tmp_file} | while read line; do
		if [ "${line}" = "Watches established." ]; then
			break
		fi
	done
	rm ${tmp_file}

	echo ${pid}
}

function cleanup_package_files {
	target=$1
	install_dir=$2

	files_list=${BUILD_DIR}/${target}/${target}.${install_dir}_files
	if [ -e ${files_list} ]; then
		set +e
		for f in $(cat ${files_list}); do
			rm -df ${f}
		done
		set -e
	fi
}

function dirclean {
	target=$1

	if [[ ${target%-dirclean}  = *-config ]]; then
		echo "cannot dirclean a config target !"
		exit 1
	fi

	# remove files installed by the package in the final and staging dirs
	cleanup_package_files ${target} final
	cleanup_package_files ${target} staging

	rm -rf ${BUILD_DIR}/${target}
	echo " *** cleaned and removed build directory for ${target%-dirclean}"
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

	# list files which will be installed in the staging dir
	staging_inot_file=${BUILD_DIR}/${target}/${target}.staging_files
	staging_inotify_pid=$(start_watching_installed_files ${target} \
		${staging_inot_file} ${STAGING_DIR})
	# list files which will be installed in the final dir
	final_inot_file=${BUILD_DIR}/${target}/${target}.final_files
	final_inotify_pid=$(start_watching_installed_files ${target} \
		${final_inot_file} ${FINAL_DIR})

	package_name=${target%.host}
	echo " *** executing build script \"${bs}\""
	if [[ ${target} = *.host ]]; then
		# use host toolchain for host tools build...
		PKG_CONFIG_PATH=${HOST_PKG_CONFIG_PATH} \
		PKG_CONFIG=${HOST_PKG_CONFIG} \
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
		PKG_CONFIG_PATH=${CROSS_PKG_CONFIG_PATH} \
		PKG_CONFIG=${CROSS_PKG_CONFIG} \
		CFLAGS=${CROSS_CFLAGS} \
		CPPFLAGS=${CROSS_CPPFLAGS} \
		LDFLAGS=${CROSS_LDFLAGS} \
		AR=${CROSS_AR} \
		AS=${CROSS_AS} \
		LD=${CROSS_LD} \
		CC=${CROSS_CC} \
		CXX=${CROSS_CXX} \
		PACKAGE_NAME=${package_name} \
		PACKAGE_BUILD_DIR=${BUILD_DIR}/${package_name} \
				. ${bs} 2>&1 | \
				/usr/share/colormake/colormake.pl
		test ${PIPESTATUS[0]} -eq 0 # fail on build error
	fi
	echo " *** ${bs} executed successfully"

	kill ${staging_inotify_pid}
	staging_inotify_pid=
	kill ${final_inotify_pid}
	final_inotify_pid=

	clean_inot_file ${staging_inot_file}
	clean_inot_file ${final_inot_file}
}

function merge_skel {
	cp -rpf ${CONFIG_DIR}/skel/* ${FINAL_DIR}
	find ${FINAL_DIR} -name .gitignore -exec rm {} \;
}

function strip_final {
	if [ "${CARINO_VERSION_TYPE}" = "release" ]; then
		# we don't want to fail if we attempt to strip a script
		set +e
		for f in $(find ${FINAL_DIR} -xdev -executable -type f); do
			chmod +w $f
			${TOOLCHAIN_PREFIX}-strip $f;
		done
		set -e
	fi
}

if [ $# != 0 ]; then
	targets=$*
else
	targets=$(cat ${CONFIG_DIR}/packages)
fi

trap "on_exit" EXIT RETURN 2 3 15

create_tree_structure
for target in ${targets}; do
	build_package ${target}
done
merge_skel
strip_final
