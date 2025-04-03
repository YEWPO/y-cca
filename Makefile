ROOT_DIR = $(shell pwd)

CROSS_COMPILE ?= aarch64-linux-gnu-
THREADS ?= $(shell nproc)

RMM_DIR = $(ROOT_DIR)/rmm
TF_A_DIR = $(ROOT_DIR)/trusted-firmware-a
EDK2_HOST_DIR = $(ROOT_DIR)/edk2-host
EDK2_PLAT_DIR = $(ROOT_DIR)/edk2-platforms
EDK2_NON_OSI_DIR = $(ROOT_DIR)/edk2-non-osi

LINUX_HOST_DIR = $(ROOT_DIR)/linux-host
BUILDROOT_HOST_DIR = $(ROOT_DIR)/buildroot-host
BUILDROOT_EXTER_DIR = $(ROOT_DIR)/buildroot-external

EDK2_GUEST_DIR = $(ROOT_DIR)/edk2-guest
LINUX_GUEST_DIR = $(ROOT_DIR)/linux-guest
BUILDROOT_GUEST_DIR = $(ROOT_DIR)/buildroot-guest
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
		CROSS_COMPILE=$(CROSS_COMPILE) PLAT=qemu_sbsa \
		ENABLE_RME=1 RME_GPT_BITLOCK_BLOCK=1 DEBUG=1 LOG_LEVEL=40 \
		RMM=$(RMM_DIR)/build/Debug/rmm.img all fip
	cp $(TF_A_DIR)/build/qemu_sbsa/debug/bl1.bin $(EDK2_NON_OSI_DIR)/Platform/Qemu/Sbsa/
	cp $(TF_A_DIR)/build/qemu_sbsa/debug/fip.bin $(EDK2_NON_OSI_DIR)/Platform/Qemu/Sbsa/

edk2-host: tf-a
	$(SCRIPTS_DIR)/edk2_host_build.sh $(CROSS_COMPILE)
	truncate -s 256M $(EDK2_HOST_DIR)/Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd
	truncate -s 256M $(EDK2_HOST_DIR)/Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd
	cp $(EDK2_HOST_DIR)/Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH0.fd $(IMAGE_DIR)
	cp $(EDK2_HOST_DIR)/Build/SbsaQemuRme/RELEASE_GCC5/FV/SBSA_FLASH1.fd $(IMAGE_DIR)

linux-host:
	$(SCRIPTS_DIR)/linux_host_build.sh $(CROSS_COMPILE)

buildroot-host:
	make -C $(BUILDROOT_HOST_DIR) BR2_EXTERNAL=$(BUILDROOT_EXTER_DIR) cca_defconfig
	make -C $(BUILDROOT_HOST_DIR) -j$(THREADS)

edk2-guest:
	$(SCRIPTS_DIR)/edk2_guest_build.sh $(CROSS_COMPILE)

linux-guest:
	$(SCRIPTS_DIR)/linux_guest_build.sh $(CROSS_COMPILE)

buildroot-guest: linux-guest
	mkdir -p $(BUILDROOT_GUEST_DIR)/output/images
	cp $(LINUX_GUEST_DIR)/arch/arm64/boot/Image ${BUILDROOT_GUEST_DIR}/output/images/Image
	make -C $(BUILDROOT_GUEST_DIR) aarch64_efi_defconfig
	make -C $(BUILDROOT_GUEST_DIR) -j$(THREADS)

$(QEMU_BIN):
	$(SCRIPTS_DIR)/qemu_build.sh

qemu: $(QEMU_BIN)

virt-disk: buildroot-host linux-host edk2-host
	cp $(LINUX_HOST_DIR)/arch/arm64/boot/Image $(IMAGE_DIR)/disks/virtual/Image
	cp $(BUILDROOT_HOST_DIR)/output/images/rootfs.ext4 $(IMAGE_DIR)/rootfs.ext4
	cp $(BUILDROOT_HOST_DIR)/output/images/rootfs.cpio $(IMAGE_DIR)/rootfs.cpio
	cp $(SCRIPTS_DIR)/startup.nsh $(IMAGE_DIR)/disks/virtual/startup.nsh

build: virt-disk qemu buildroot-host buildroot-guest edk2-guest

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
		-drive format=raw,if=none,file=$(IMAGE_DIR)/rootfs.ext4,id=hd0 \
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

.PHONY: init rmm tf-a edk2-host edk2-guest linux-host linux-guest buildroot-host buildroot-guest qemu virt-disk run
