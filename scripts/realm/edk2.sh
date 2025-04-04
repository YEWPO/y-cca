#!/bin/bash

qemu-system-aarch64 \
  -M confidential-guest-support=rme0 \
  -object rme-guest,id=rme0,measurement-algorithm=sha512 \
  -cpu host -M virt -enable-kvm -M gic-version=3,its=on \
  -smp 2 -m 2G -nographic \
  -bios /mnt/edk2-guest/Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd \
  -nodefaults \
  -device virtio-blk-pci,drive=hd0 \
  -drive if=none,id=hd0,file=/mnt/buildroot-guest/output/images/disk.img,format=raw \
  -device virtio-serial-pci \
  -device virtconsole,chardev=virtiocon0 \
  -chardev stdio,mux=on,id=virtiocon0,signal=off \
  -mon chardev=virtiocon0,mode=readline \
  -device virtio-net-pci,netdev=net0,romfile= \
  -netdev user,id=net0 \
  < /dev/hvc1 >/dev/hvc1
