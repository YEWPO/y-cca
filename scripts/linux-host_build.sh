#!/usr/bin/env bash

ROOT_DIR=$(pwd)
LINUX_HOST_DIR=$ROOT_DIR/linux-host

cd $LINUX_HOST_DIR
make ARCH=arm64 CROSS_COMPILE=$1 defconfig
./scripts/config -e VIRT_DRIVERS -e ARM_CCA_GUEST -e CONFIG_HZ_100 \
  -d CONFIG_HZ_250 -e CONFIG_MACVLAN -e CONFIG_MACVTAP \
	-e VMGENID -d NITRO_ENCLAVES -d ARM_PKVM_GUEST
make ARCH=arm64 CROSS_COMPILE=$1 -j$2 Image

if [ $? -ne 0 ]; then
    exit 1
fi

cd $ROOT_DIR
