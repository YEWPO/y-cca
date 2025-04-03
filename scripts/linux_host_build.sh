#!/usr/bin/env bash

ROOT_DIR=$(pwd)
LINUX_HOST_DIR=$ROOT_DIR/linux-host

cd $LINUX_HOST_DIR
make ARCH=arm64 CROSS_COMPILE=$1 defconfig
make ARCH=arm64 CROSS_COMPILE=$1 -j$(nproc) Image

if [ $? -ne 0 ]; then
    exit 1
fi

cd $ROOT_DIR
