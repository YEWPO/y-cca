#!/usr/bin/env bash

ROOT_DIR=$(pwd)
QEMU_DIR=$ROOT_DIR/qemu

cd $QEMU_DIR
./configure --target-list=aarch64-softmmu --enable-slirp --disable-docs --disable-werror
make -j`nproc`

if [ $? -ne 0 ]; then
    exit 1
fi

cd $ROOT_DIR
