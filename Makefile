ROOT_DIR = $(shell pwd)

CROSS_COMPILE ?= aarch64-linux-gnu-
THREADS ?= $(shell nproc)

RMM_DIR = $(ROOT_DIR)/rmm
TF_A_DIR = $(ROOT_DIR)/trusted-firmware-a
EDK2_DIR = $(ROOT_DIR)/edk2
EDK2_PLAT_DIR = $(ROOT_DIR)/edk2-platforms
EDK2_NON_OSI_DIR = $(ROOT_DIR)/edk2-non-osi
LINUX_DIR = $(ROOT_DIR)/linux
BUILDROOT_DIR = $(ROOT_DIR)/buildroot
BUILDROOT_EXTER_DIR = $(ROOT_DIR)/buildroot-external
QEMU_DIR = $(ROOT_DIR)/qemu

IMAGE_DIR = $(ROOT_DIR)/images

# Build the Softwares
rmm:
	export CROSS_COMPILE=$(CROSS_COMPILE)
	cmake -S $(RMM_DIR) -DCMAKE_BUILD_TYPE=Debug -DRMM_CONFIG=qemu_sbsa_defcfg -B $(RMM_DIR)/build-sbsa
	cmake --build $(RMM_DIR)/build-sbsa
	cp $(RMM_DIR)/build-sbsa/Debug/rmm.img $(IMAGE_DIR)

tf-a: rmm
	make -C $(TF_A_DIR) \
		CROSS_COMPILE=aarch64-linux-gnu- PLAT=qemu_sbsa \
		ENABLE_RME=1 RME_GPT_BITLOCK_BLOCK=1 DEBUG=1 LOG_LEVEL=40 \
		RMM=$(RMM_DIR)/build-sbsa/Debug/rmm.img all fip
	cp $(TF_A_DIR)/build/qemu_sbsa/debug/bl1.bin $(EDK2_NON_OSI_DIR)/Platform/Qemu/Sbsa/
	cp $(TF_A_DIR)/build/qemu_sbsa/debug/fip.bin $(EDK2_NON_OSI_DIR)/Platform/Qemu/Sbsa/

edk2: tf-a
	./rmm_build.sh
	truncate -s 256M Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd
	truncate -s 256M Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd
	cp Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd $(IMAGE_DIR)
	cp Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd $(IMAGE_DIR)

linux:
	make -C $(LINUX_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE) defconfig
	$(LINUX_DIR)/scripts/config -e VIRT_DRIVERS -e ARM_CCA_GUEST -e CONFIG_HZ_100 \
		-d CONFIG_HZ_250 -e CONFIG_MACVLAN -e CONFIG_MACVTAP \
		-e VMGENID -d NITRO_ENCLAVES -d ARM_PKVM_GUEST
	make -C $(LINUX_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE) -j$(THREADS) Image

buildroot:
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BUILDROOT_EXTER_DIR) cca_defconfig
	make -C $(BUILDROOT_DIR) -j$(THREADS)
	cp $(BUILDROOT_DIR)/output/images/rootfs.ext4 $(IMAGE_DIR)
	cp $(BUILDROOT_DIR)/output/images/rootfs.cpio $(IMAGE_DIR)

qemu:
	cd $(QEMU_DIR)
	$(QEMU_DIR)/configure --target-list=aarch64-softmmu --enable-slirp --disable-docs
	make -C $(QEMU_DIR) -j$(THREADS)

virt-disk: buildroot linux edk2
	cp $(LINUX_DIR)/arch/arm64/boot/Image $(IMAGE_DIR)/disks/virtual/Image
	echo "mode 100 31\npci\nfs0:\Image root=/dev/vda console=hvc0\nreset -c" > $(IMAGE_DIR)/disks/virtual/startup.nsh

build: virt-disk qemu buildroot
	./create_display_panes.sh
	$(QEMU_DIR)/build/qemu-system-aarch64 \
		-machine sbsa-ref -m 8G \
		-cpu max,x-rme=on,sme=off,pauth-impdef=on \
		-drive file=$(IMAGE_DIR)/SBSA_FLASH0.fd,format=raw,if=pflash \
		-drive file=$(IMAGE_DIR)/SBSA_FLASH1.fd,format=raw,if=pflash \
		-drive file=fat:rw:$(IMAGE_DIR)/disks/virtual,format=raw \
		-drive format=raw,if=none,file=$(BUILDROOT_DIR)/output/images/rootfs.ext4,id=hd0 \
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
		-fsdev local,security_model=none,path=$(ROOT_DIR),id=shr0
	tmux select-window -l

run: build
	./check_tmux.sh $(ROOT_DIR)

# Clone needed repositories and install dependencies
init:
	./init.sh

.PHONY: init rmm tf-a edk2 linux buildroot qemu virt-disk run
