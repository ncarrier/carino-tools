#!/bin/bash

set -x
set -e

readonly TRUE=0
readonly FALSE=1

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
rm -rf out
CARINO_VERSION_TYPE="release" ./build.sh

# generate the SD card image
sudo ./gen_sd.sh # asks for the root password, how to get rid of that ? TODO
mkdir -p versions
mv out/carino.img versions/${vehicle_name}-${version}.img

