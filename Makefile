export BL31 ?= $(PWD)/trusted-firmware-a/build/rk3568/release/bl31/bl31.elf 
export ROCKCHIP_TPL ?= $(PWD)/rockchip-images/rk3566_ddr_1056MHz_v1.23.bin 
#
# CROSS_COMPILE ?= $(HOME)/bin/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
export CROSS_COMPILE ?= aarch64-none-linux-gnu-

BUILD_DIR ?= build

######################### Help #####################
help:
	$(info -)
	$(info Put the cross compiler on your path: aarch64-none-linux-gnu-)
	$(info -)
	$(info You can set the build dir like this: )
	$(info     make BUILD_DIR=test1 u-boot)
	$(info -)
	$(info Use the flash-partition.sh script to prepare an SD Card)
	$(info -)

######################### TFA #####################
tfa:
	rm -rf $(BUILD_DIR)/tfa
	mkdir -p $(BUILD_DIR)/tfa
	#TODO

.PHONY: tfa

######################### U-Boot #####################
u-boot:
	rm -rf $(BUILD_DIR)/u-boot
	mkdir -p $(BUILD_DIR)/u-boot
	cd u-boot && make distclean
	cd u-boot && make O=../$(BUILD_DIR)/u-boot radxa-zero-3-rk3566_defconfig
	cd u-boot && make O=../$(BUILD_DIR)/u-boot 

# alias
uboot: u-boot

.PHONY: u-boot uboot

######################### Linux #####################

linux:

.PHONY: linux

######################### Filesystem #####################

fs:

.PHONY: fs

######################### Flashing an SD Card #####################

# Stem for partitions, might be /dev/sdb
SDCARD_DISKP ?= /dev/disk4s

# Where partition 2 of the SD Card is mounted (must already be formatted as FATFS)
SDCARD_LINUX_IMG_VOL ?= /Volumes/LINIMG  

flash-sd:
	sudo dd if=$(BUILD_DIR)/u-boot/u-boot-rockchip.bin of=$(SDCARD_DISKP)1 seek=64
	cp $(BUILD_DIR)/linux/Image $(SDCARD_LINUX_IMG_VOL)
	cp $(BUILD_DIR)/linux/rk3566-radxa-zero-3e.dtb $(SDCARD_LINUX_IMG_VOL)
	sudo dd if=rootfs.ext2 of=$(SDCARD_DISKP)3
	$(info Please unmount SD Card now)

clean:
	rm -rf $(BUILD_DIR)
