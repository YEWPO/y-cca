#!/usr/bin/env bash

export PACKAGES_PATH=$PWD/edk2:$PWD/edk2-platforms:$PWD/edk2-non-osi
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
. edk2/edksetup.sh
make -C edk2/BaseTools
build -b RELEASE -a AARCH64 -t GCC5 -D ENABLE_RME --pcd PcdUefiShellDefaultBootEnable=1 \
    --pcd PcdShellDefaultDelay=0 -p edk2-platforms/Platform/Qemu/SbsaQemu/SbsaQemu.dsc
