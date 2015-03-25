#!/bin/bash

set -x
set -e

readonly TRUE=0
readonly FALSE=1

export CARINO_VERSION_TYPE="release"
. config/build_config

function usage {
	echo "usage : release.sh VERSION"
	exit $1
}

if [ -z "$1" ]; then
	usage 1
fi
version=$1

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
repo manifest --revision-as-HEAD -o .repo/manifests/${CARINO_VEHICLE}.xml
cd .repo/manifests
git add ${CARINO_VEHICLE}.xml
git commit -m "prepare version ${version} for vehicle ${CARINO_VEHICLE}"
git tag ${CARINO_VEHICLE}-${version}-tag
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
mv ${OUT_DIR}/carino.img ${VERSIONS_DIR}/${CARINO_VEHICLE}-${version}.img

# create the release archive
tar cvjf ${VERSIONS_DIR}/${CARINO_VEHICLE}-${version}.tar.bz2 \
	${VERSIONS_DIR}/${CARINO_VEHICLE}-${version}.img

# cleanup
rm -f ${VERSIONS_DIR}/${CARINO_VEHICLE}-${version}.img

# version the new version (funny isn't it ?)
cd ${VERSIONS_DIR}
git add ${CARINO_VEHICLE}-${version}.tar.bz2
git commit -m "${CARINO_VEHICLE} version ${version}"
cd -

