ROOT_DIR = $(shell pwd)

CROSS_COMPILE ?= aarch64-linux-gnu-
THREADS ?= $(shell nproc)

# Build the Softwares
rmm:
	cd $(ROOT_DIR)/rmm
	cmake -DCMAKE_BUILD_TYPE=Debug -DRMM_CONFIG=qemu_sbsa_defcfg -B build-sbsa
	cmake --build build-sbsa
	cp build-sbsa/Debug/rmm.img ../images/

tf-a: rmm
	cd $(ROOT_DIR)/trusted-firmware-a
	make -j CROSS_COMPILE=aarch64-linux-gnu- PLAT=qemu_sbsa ENABLE_RME=1 RME_GPT_BITLOCK_BLOCK=1 \
		DEBUG=1 LOG_LEVEL=40 \
		RMM=../rmm/build-sbsa/Debug/rmm.img all fip
	cp build/qemu_sbsa/debug/bl1.bin ../edk2-non-osi/Platform/Qemu/Sbsa/
	cp build/qemu_sbsa/debug/fip.bin ../edk2-non-osi/Platform/Qemu/Sbsa/

edk2: tf-a
	cd $(ROOT_DIR)
	export PACKAGES_PATH=$(ROOT_DIR)/edk2:$(ROOT_DIR)/edk2-platforms:$(ROOT_DIR)/edk2-non-osi
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
	. edk2/edksetup.sh
	make -C edk2/BaseTools
	build -b RELEASE -a AARCH64 -t GCC5 -D ENABLE_RME --pcd PcdUefiShellDefaultBootEnable=1 \
		--pcd PcdShellDefaultDelay=0 -p edk2-platforms/Platform/Qemu/SbsaQemu/SbsaQemu.dsc
	truncate -s 256M Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd
	truncate -s 256M Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd
	cp Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd images/
	cp Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd images/

linux:
	cd $(ROOT_DIR)/linux
	make ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE) defconfig
	scripts/config -e VIRT_DRIVERS -e ARM_CCA_GUEST -e CONFIG_HZ_100 \
		-d CONFIG_HZ_250 -e CONFIG_MACVLAN -e CONFIG_MACVTAP \
		-e VMGENID -d NITRO_ENCLAVES -d ARM_PKVM_GUEST
	make ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE) -j$(THREADS) Image

buildroot:
	cd $(ROOT_DIR)/buildroot
	make BR2_EXTERNAL=path/to/buildroot-external-cca/ cca_defconfig
	make -j$(THREADS)
	cp output/images/rootfs.ext4 ../images/
	cp output/images/rootfs.cpio ../images/

qemu:
	cd $(ROOT_DIR)/qemu
	./configure --target-list=aarch64-softmmu --enable-slirp --disable-docs
	make -j$(THREADS)

virt-disk: buildroot linux edk2
	cd $(ROOT_DIR)
	cp $(ROOT_DIR)/linux/arch/arm64/boot/Image $(ROOT_DIR)/images/disks/virtual/Image
	echo "mode 100 31\npci\nfs0:\Image root=/dev/vda console=hvc0\nreset -c" > $(ROOT_DIR)/images/disks/virtual/startup.nsh

run: virt-disk qemu
	cd $(ROOT_DIR)
	qemu/build/qemu-system-aarch64 \
		-machine sbsa-ref -m 8G \
		-cpu max,x-rme=on,sme=off,pauth-impdef=on \
		-drive file=images/SBSA_FLASH0.fd,format=raw,if=pflash \
		-drive file=images/SBSA_FLASH1.fd,format=raw,if=pflash \
		-drive file=fat:rw:images/disks/virtual,format=raw \
		-drive format=raw,if=none,file=buildroot/output/images/rootfs.ext4,id=hd0 \
		-device virtio-blk-pci,drive=hd0 \
		-serial tcp:localhost:54320 \
		-serial tcp:localhost:54321 \
		-chardev socket,mux=on,id=hvc0,port=54322,host=localhost \
		-device virtio-serial-pci \
		-device virtconsole,chardev=hvc0 \
		-chardev socket,mux=on,id=hvc1,port=54323,host=localhost \
		-device virtio-serial-pci \
		-device virtconsole,chardev=hvc1 \
		-device virtio-9p-pci,fsdev=shr0,mount_tag=shr0 \
		-fsdev local,security_model=none,path=.,id=shr0

# Clone needed repositories and install dependencies
init:
	./init.sh

.PHONY: init rmm tf-a edk2 linux buildroot qemu virt-disk run
