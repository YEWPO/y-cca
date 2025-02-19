#!/usr/bin/env bash

ROOT_DIR=$(pwd)
RMM_DIR=${ROOT_DIR}/rmm

export CROSS_COMPILE=aarch64-linux-gnu-
cmake -DCMAKE_BUILD_TYPE=Debug -DRMM_CONFIG=qemu_sbsa_defcfg -B build-sbsa
cmake --build build-sbsa
