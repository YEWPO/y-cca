qemu-system-aarch64 \
  -M confidential-guest-support=rme0 \
  -object rme-guest,id=rme0,measurement-algorithm=sha512,personalization-value=abcd \
  -nodefaults \
  -chardev stdio,mux=on,id=virtiocon0,signal=off \
  -device virtio-serial-pci \
  -device virtconsole,chardev=virtiocon0 \
  -mon chardev=virtiocon0,mode=readline \
  -kernel /mnt/images/disks/virtual/Image \
  -initrd /mnt/images/rootfs.cpio \
  -device virtio-net-pci,netdev=net0,romfile= \
  -netdev user,id=net0 \
  -cpu host -M virt -enable-kvm -M gic-version=3,its=on \
  -smp 2 -m 512M -nographic \
  -append console=hvc0 < /dev/hvc1 >/dev/hvc1
