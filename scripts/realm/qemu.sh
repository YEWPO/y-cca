#!/bin/bash

qemu-system-aarch64 \
  -M confidential-guest-support=rme0 \
  -object rme-guest,id=rme0,measurement-algorithm=sha512 \
  -cpu host -M virt -enable-kvm -M gic-version=3,its=on \
  -smp 2 -m 2G -nographic \
  -kernel /mnt/linux-guest/arch/arm64/boot/Image \
  -initrd /mnt/buildroot-host/output/images/rootfs.cpio \
  -nodefaults \
  -device virtio-serial-pci \
  -device virtconsole,chardev=virtiocon0 \
  -chardev stdio,mux=on,id=virtiocon0,signal=off \
  -mon chardev=virtiocon0,mode=readline \
  -device virtio-net-pci,netdev=net0,romfile= \
  -netdev user,id=net0 \
  -append console=hvc0 < /dev/hvc1 >/dev/hvc1
