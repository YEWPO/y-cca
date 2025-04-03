#!/usr/bin/env bash

ROOT_DIR=$(pwd)
EDK2_HOST_DIR=$ROOT_DIR/edk2-host

cd $EDK2_HOST_DIR

export PACKAGES_PATH=$ROOT_DIR/edk2-host:$ROOT_DIR/edk2-platforms:$ROOT_DIR/edk2-non-osi
export GCC5_AARCH64_PREFIX=$1
shift
make -C BaseTools -j$(nproc)
source edksetup.sh
build -b RELEASE -a AARCH64 -t GCC5 -D ENABLE_RME --pcd PcdUefiShellDefaultBootEnable=1 \
  --pcd PcdShellDefaultDelay=0 -p $ROOT_DIR/edk2-platforms/Platform/Qemu/SbsaQemu/SbsaQemu.dsc

if [ $? -ne 0 ]; then
  exit 1
fi
