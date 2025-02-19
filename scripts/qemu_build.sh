#!/usr/bin/env bash

ROOT_DIR=$(pwd)
QEMU_DIR=$ROOT_DIR/qemu

cd $QEMU_DIR
./configure --target-list=aarch64-softmmu --enable-slirp --disable-docs
make -j`nproc`
cd $ROOT_DIR
