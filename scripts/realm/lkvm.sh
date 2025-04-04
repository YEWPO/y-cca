#!/bin/bash

lkvm run --realm -c 2 -m 2G -k /mnt/linux-guest/arch/arm64/boot/Image -d /mnt/buildroot-guest/output/images/rootfs.ext4 --restricted_mem -p "console=hvc0 root=/dev/vda" < /dev/hvc1 > /dev/hvc1
