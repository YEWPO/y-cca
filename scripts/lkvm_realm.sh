#!/bin/bash

lkvm run --realm -c 1 -m 2G -k /mnt/images/disks/virtual/Image-guest -d /mnt/images/rootfs-guest.ext4 --restricted_mem -p "console=hvc0 root=/dev/vda" < /dev/hvc1 > /dev/hvc1
