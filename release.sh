#!/bin/bash

set -x
set -e

readonly TRUE=0
readonly FALSE=1

export CARINO_VERSION_TYPE="release"
. config/build_config

function usage {
	echo "usage : release.sh VEHICLE_NAME VERSION"
	exit $1
}

if [ -z "$1" ]; then
	usage 1
fi
vehicle_name=$1

if [ -z "$2" ]; then
	usage 1
fi
version=$2

# be sure the manifest has no local modifications
cd .repo/manifests
if git diff --quiet; then
	dirty=FALSE
else
	dirty=TRUE
	git stash
fi
cd -

# generate, commit and tag the manifest for the current software's state
repo manifest --revision-as-HEAD -o .repo/manifests/${vehicle_name}.xml
cd .repo/manifests
git add ${vehicle_name}.xml
git commit -m "prepare version ${version} for vehicle ${vehicle_name}"
git tag ${vehicle_name}-${version}-tag
cd -

if [ ${dirty} = TRUE ]; then
	cd .repo/manifests
	git stash pop
	cd -
fi

# rebuild from scratch the whole project
rm -rf ${OUT_DIR}
./build.sh

# generate the SD card image
# asks for the root password, how to get rid of that ? TODO
sudo CARINO_VERSION_TYPE="release" ./gen_sd.sh

mkdir -p ${VERSIONS_DIR}
mv ${OUT_DIR}/carino.img ${VERSIONS_DIR}/${vehicle_name}-${version}.img

# create the release archive
tar cvjf ${VERSIONS_DIR}/${vehicle_name}-${version}.tar.bz2 \
	${VERSIONS_DIR}/${vehicle_name}-${version}.img

# cleanup
rm -f ${VERSIONS_DIR}/${vehicle_name}-${version}.img

# version the new version (funny isn't it ?)
cd ${VERSIONS_DIR}
git add ${vehicle_name}-${version}.tar.bz2
git commit -m "${vehicle_name} version ${version}"
cd -

