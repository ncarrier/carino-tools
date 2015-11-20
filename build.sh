#!/bin/bash

export ALCHEMY_WORKSPACE_DIR=${PWD}
export ALCHEMY_TARGET_SCAN_PRUNE_DIRS=${ALCHEMY_WORKSPACE_DIR}
export ALCHEMY_TARGET_SCAN_ADD_DIRS=${ALCHEMY_WORKSPACE_DIR}/packages
export ALCHEMY_HOME=alchemy
if [ -z $ALCHEMY_USE_COLORS ]
then
	export ALCHEMY_USE_COLORS=1
fi

# once we'll have multiple products or variants, we will have to specify the
# next two, via command line parameters
export TARGET_PRODUCT=carino
TARGET_PRODUCT_VARIANT=${variant:-obstination}
export TARGET_PRODUCT_VARIANT

export ALCHEMY_TARGET_CONFIG_DIR=${ALCHEMY_WORKSPACE_DIR}/products/${TARGET_PRODUCT}/${TARGET_PRODUCT_VARIANT}/config
export ALCHEMY_TARGET_OUT=${ALCHEMY_WORKSPACE_DIR}/out/${TARGET_PRODUCT}-${TARGET_PRODUCT_VARIANT}

if [ -n "$(which ccache)" ]
then
	export PATH=/usr/lib/ccache:$PATH
	export USE_CCACHE=1
fi

${ALCHEMY_HOME}/scripts/alchemake "$@"
