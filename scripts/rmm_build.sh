#!/usr/bin/env bash

ROOT_DIR=$(pwd)
RMM_DIR=${ROOT_DIR}/rmm

cd $RMM_DIR
export CROSS_COMPILE=aarch64-linux-gnu-
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug -DRMM_CONFIG=qemu_sbsa_defcfg -B build
cmake --build build
cd $ROOT_DIR
