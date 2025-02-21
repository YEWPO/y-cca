#!/usr/bin/env bash

ROOT_DIR=$(pwd)
RMM_DIR=${ROOT_DIR}/rmm

cd $RMM_DIR
export CROSS_COMPILE=aarch64-linux-gnu-
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_BUILD_TYPE=Debug -DRMM_CONFIG=qemu_sbsa_defcfg \
  -DRMM_V1_1=$1 \
  -B build

cmake --build build

if [ $? -ne 0 ]; then
  exit 1
fi

cd $ROOT_DIR
