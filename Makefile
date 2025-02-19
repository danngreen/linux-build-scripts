# Uncomment this for CM3 with IO board:
UBOOT_BOARD ?= radxa-cm3-io-rk3566_defconfig
LINUX_DTB ?= rk3566-radxa-cm3-io.dtb

# Uncomment this for radxa zero 3e board:
# UBOOT_BOARD ?= radxa-zero-3-rk3566_defconfig
# LINUX_DTB ?= rk3566-radxa-zero-3e.dtb

# SD Card device stem for partitions
# SDCARD_DISKP ?= /dev/disk4s
# SDCARD_DISK ?= /dev/disk4
#
# SDCARD_DISKP ?= /dev/sda
# SDCARD_DISK ?= /dev/sda

SDCARD_DISKP ?= $(SDCARD_DISK)

# Where partition 2 of the SD Card is mounted (must already be formatted as FATFS)
# SDCARD_LINUX_IMG_VOL ?= /Volumes/LINIMG  
SDCARD_LINUX_IMG_VOL ?= /media/sd

############################

# This file is provided by rockchip in the rkbin github repo
export ROCKCHIP_TPL ?= $(PWD)/rockchip-images/rk3566_ddr_1056MHz_v1.23.bin 

export CROSS_COMPILE ?= aarch64-none-linux-gnu-

BUILD_DIR ?= $(PWD)/build

######################### Help #####################
help:
	$(info This is meant to be run from within the Docker container)
	$(info -)
	$(info Available targets:)
	$(info    u-boot    tfa    linux    linux-modules    fs    all    flash-sd)
	$(info -)
	$(info Choose your board with UBOOT_BOARD and LINUX_DTB env vars -- see commented lines at top of this Makefile)
	$(info -)
	$(info You can set the build dir like this: )
	$(info     make BUILD_DIR=test1 all)
	$(info -)
	$(info Use the format-partition-sdcard.sh script to prepare an SD Card)
	$(info before running `make flash-sd`)
	$(info )

.PHONY: help

######################### TFA #####################
BL31 ?= $(BUILD_DIR)/tfa/rk3568/release/bl31/bl31.elf 

tfa: $(BL31)

$(BL31):
	mkdir -p $(BUILD_DIR)/tfa
	cd trusted-firmware-a && make BUILD_BASE=$(BUILD_DIR)/tfa realclean
	cd trusted-firmware-a && make BUILD_BASE=$(BUILD_DIR)/tfa PLAT=rk3568


clean-tfa:
	rm -rf $(BUILD_DIR)/tfa
	cd trusted-firmware-a && make realclean

.PHONY: tfa 


######################### U-Boot #####################
u-boot: $(BL31)
	mkdir -p $(BUILD_DIR)/u-boot
	cd u-boot && make O=$(BUILD_DIR)/u-boot $(UBOOT_BOARD)
	cd u-boot && scripts/kconfig/merge_config.sh -O '$(BUILD_DIR)/u-boot' '$(BUILD_DIR)/u-boot/.config' '../configs/u-boot.cfg' 
	cd u-boot && make O=$(BUILD_DIR)/u-boot BL31=$(BL31)

clean-u-boot:
	rm -rf $(BUILD_DIR)/u-boot
	cd u-boot && make distclean

# alias
uboot: u-boot

.PHONY: u-boot uboot

######################### Linux #####################

linux:
	mkdir -p $(BUILD_DIR)/linux
	cd linux && make O=$(BUILD_DIR)/linux ARCH=arm64 defconfig
	cd linux && make O=$(BUILD_DIR)/linux ARCH=arm64 -j8

linux-modules:
	cd linux && make O=../build/linux ARCH=arm64 INSTALL_MOD_PATH=../fs-overlay modules_install

clean-linux:
	rm -rf $(BUILD_DIR)/linux
	cd linux && make distclean

.PHONY: linux clean-linux linux-modules

######################### Filesystem #####################

FS_DEFCONFIG ?= $(PWD)/configs/buildroot_cortexa55-alsa-kernel612_defconfig

fs: linux-modules
	mkdir -p $(BUILD_DIR)/fs
	cd buildroot && make O=$(BUILD_DIR)/fs defconfig \
		BR2_DEFCONFIG=$(FS_DEFCONFIG) \
		BR2_ROOTFS_OVERLAY=../fs-overlay
	cd buildroot && make O=$(BUILD_DIR)/fs 

clean-fs:
	rm -rf $(BUILD_DIR)/fs
	cd buildroot && make distclean

.PHONY: fs 

########################## ALL ####################################

all: u-boot linux fs

######################### Flashing an SD Card #####################

flash-u-boot:
	sudo umount $(SDCARD_DISK)
	sudo dd if=$(BUILD_DIR)/u-boot/u-boot-rockchip.bin of=$(SDCARD_DISK) seek=64

flash-linux:
	sudo mount $(SDCARD_DISKP)2 $(SDCARD_LINUX_IMG_VOL)
	sudo cp $(BUILD_DIR)/linux/arch/arm64/boot/Image $(SDCARD_LINUX_IMG_VOL)
	sudo cp $(BUILD_DIR)/linux/arch/arm64/boot/dts/rockchip/$(LINUX_DTB) $(SDCARD_LINUX_IMG_VOL)
	sudo umount $(SDCARD_LINUX_IMG_VOL)

flash-rootfs:
	sudo dd if=$(BUILD_DIR)/fs/images/rootfs.ext2 of=$(SDCARD_DISKP)3

flash-sd: flash-u-boot flash-linux flash-rootfs
	$(info Done! Ready to boot from SD card)

clean:
	rm -rf $(BUILD_DIR)

