#!/usr/bin/env bash

#Usage: git_clone <repo> <dir> <branch> <shallow> <submodules>
#repo: repository to clone
#dir: directory to clone into
#branch: branch to clone
#shallow: shallow clone
#submodules: clone submodules
function git_clone() {
  echo a
}


#Check tools installation
#Usage: check_tools <tool>
#tool: tool to check
function check_tool() {
  if ! command -v $1 &> /dev/null; then
    echo "$1 is not installed. Please install it."
    exit 1
  fi
}

#Check tools installation
check_tool git
check_tool make
check_tool aarch64-linux-gnu-gcc
check_tool cmake
check_tool ninja
check_tool flex
check_tool bison

#Create directory for build images
mkdir -p images/disks/virtual/

#Git Repo Configuration
#         repo                                                                            dir                 branch          shallow   submodules
git_clone https://github.com/YEWPO/y-rmm.git                                              rmm                 master          false     true
git_clone https://github.com/tianocore/edk2-non-osi.git                                   edk2-non-osi        master          false     false
git_clone https://git.codelinaro.org/linaro/dcap/tf-a/trusted-firmware-a.git              trusted-firmware-a  cca/v4          false     false
git_clone https://github.com/tianocore/edk2-platforms.git                                 edk2-platforms      master          false     true
git_clone https://github.com/tianocore/edk2.git                                           edk2                master          false     true
git_clone https://gitlab.arm.com/linux-arm/linux-cca                                      linux               cca-full/v5+v7  true      false
git_clone https://git.codelinaro.org/linaro/dcap/buildroot-external-cca.git               buildroot-external  master          false     false
git_clone https://gitlab.com/buildroot.org/buildroot.git                                  buildroot           master          true      false
git_clone https://gitlab.com/qemu-project/qemu.git                                        qemu                master          true      false

