#!/usr/bin/env bash

ROOT_DIR=$(pwd)
EDK2_GUEST_DIR=$ROOT_DIR/edk2-guest

cd $EDK2_GUEST_DIR
export GCC5_AARCH64_PREFIX=$1
shift
make -C BaseTools -j$(nproc)
source edksetup.sh
build -b DEBUG -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtQemu.dsc

if [ $? -ne 0 ]; then
  exit 1
fi
