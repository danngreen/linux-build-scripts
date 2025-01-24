# This file is provided by rockchip in the rkbin github repo
export ROCKCHIP_TPL ?= $(PWD)/rockchip-images/rk3566_ddr_1056MHz_v1.23.bin 

export CROSS_COMPILE ?= aarch64-none-linux-gnu-

BUILD_DIR ?= $(PWD)/build

######################### Help #####################
help:
	$(info -)
	$(info Available targets:)
	$(info    u-boot    tfa    linux    fs)
	$(info -)
	$(info Put the cross compiler on your path: aarch64-none-linux-gnu-)
	$(info -)
	$(info You can set the build dir like this: )
	$(info     make BUILD_DIR=test1 u-boot)
	$(info -)
	$(info Use the flash-partition.sh script to prepare an SD Card)
	$(info -)

######################### TFA #####################
BL31 ?= $(BUILD_DIR)/tfa/rk3568/release/bl31/bl31.elf 

tfa: $(BL31)

$(BL31):
	mkdir -p $(BUILD_DIR)/tfa
	cd trusted-firmware-a && make BUILD_BASE=../$(BUILD_DIR)/tfa realclean
	cd trusted-firmware-a && make BUILD_BASE=../$(BUILD_DIR)/tfa PLAT=rk3568


clean-tfa:
	rm -rf $(BUILD_DIR)/tfa
	cd trusted-firmware-a && make realclean

.PHONY: tfa 


######################### U-Boot #####################
u-boot: $(BL31)
	mkdir -p $(BUILD_DIR)/u-boot
	cd u-boot && make O=../$(BUILD_DIR)/u-boot radxa-zero-3-rk3566_defconfig
	cd u-boot && make O=../$(BUILD_DIR)/u-boot BL31=$(BL31)

clean-u-boot:
	rm -rf $(BUILD_DIR)/u-boot
	cd u-boot && make distclean

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

