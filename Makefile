ROOT_DIR = $(shell pwd)

CROSS_COMPILE ?= aarch64-linux-gnu-
THREADS ?= $(shell nproc)

RMM_DIR = $(ROOT_DIR)/rmm
TF_A_DIR = $(ROOT_DIR)/trusted-firmware-a
EDK2_DIR = $(ROOT_DIR)/edk2
EDK2_PLAT_DIR = $(ROOT_DIR)/edk2-platforms
EDK2_NON_OSI_DIR = $(ROOT_DIR)/edk2-non-osi
LINUX_HOST_DIR = $(ROOT_DIR)/linux-host
BUILDROOT_DIR = $(ROOT_DIR)/buildroot
BUILDROOT_EXTER_DIR = $(ROOT_DIR)/buildroot-external
QEMU_DIR = $(ROOT_DIR)/qemu

IMAGE_DIR = $(ROOT_DIR)/images
SCRIPTS_DIR = $(ROOT_DIR)/scripts

QEMU_BIN = $(QEMU_DIR)/build/qemu-system-aarch64

RMM_V1_1 ?= OFF

# Build the Softwares
rmm:
	$(SCRIPTS_DIR)/rmm_build.sh $(RMM_V1_1)
	cp $(RMM_DIR)/build/Debug/rmm.img $(IMAGE_DIR)

tf-a: rmm
	make -C $(TF_A_DIR) \
		CROSS_COMPILE=aarch64-linux-host-gnu- PLAT=qemu_sbsa \
		ENABLE_RME=1 RME_GPT_BITLOCK_BLOCK=1 DEBUG=1 LOG_LEVEL=40 \
		RMM=$(RMM_DIR)/build/Debug/rmm.img all fip
	cp $(TF_A_DIR)/build/qemu_sbsa/debug/bl1.bin $(EDK2_NON_OSI_DIR)/Platform/Qemu/Sbsa/
	cp $(TF_A_DIR)/build/qemu_sbsa/debug/fip.bin $(EDK2_NON_OSI_DIR)/Platform/Qemu/Sbsa/

edk2: tf-a
	$(SCRIPTS_DIR)/edk2_build.sh
	truncate -s 256M Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd
	truncate -s 256M Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd
	cp Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd $(IMAGE_DIR)
	cp Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd $(IMAGE_DIR)

linux-host:
	make -C $(LINUX_HOST_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE) defconfig
	$(LINUX_HOST_DIR)/scripts/config -e VIRT_DRIVERS -e ARM_CCA_GUEST -e CONFIG_HZ_100 \
		-d CONFIG_HZ_250 -e CONFIG_MACVLAN -e CONFIG_MACVTAP \
		-e VMGENID -d NITRO_ENCLAVES -d ARM_PKVM_GUEST
	make -C $(LINUX_HOST_DIR) ARCH=arm64 CROSS_COMPILE=$(CROSS_COMPILE) -j$(THREADS) Image

buildroot:
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BUILDROOT_EXTER_DIR) cca_defconfig
	make -C $(BUILDROOT_DIR) -j$(THREADS)
	cp $(BUILDROOT_DIR)/output/images/rootfs.ext4 $(IMAGE_DIR)
	cp $(BUILDROOT_DIR)/output/images/rootfs.cpio $(IMAGE_DIR)

$(QEMU_BIN):
	$(SCRIPTS_DIR)/qemu_build.sh

qemu: $(QEMU_BIN)

virt-disk: buildroot linux-host edk2
	cp $(LINUX_HOST_DIR)/arch/arm64/boot/Image $(IMAGE_DIR)/disks/virtual/Image-host
	cp $(SCRIPTS_DIR)/startup.nsh $(IMAGE_DIR)/disks/virtual/startup.nsh

build: virt-disk qemu buildroot

run-only:
	-pkill -f "qemu-system-aarch64"
	-tmux kill-window -t "Arm CCA"
	$(SCRIPTS_DIR)/create_display_panes.sh
	$(QEMU_BIN) \
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
		-fsdev local,security_model=none,path=$(ROOT_DIR),id=shr0 \
		-nographic &
	tmux select-window -l

run:
	$(SCRIPTS_DIR)/check_tmux.sh

# Clone needed repositories and install dependencies
init:
	$(SCRIPTS_DIR)/init.sh

.PHONY: init rmm tf-a edk2 linux-host buildroot qemu virt-disk run
