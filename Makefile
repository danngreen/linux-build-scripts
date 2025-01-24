export BL31 ?= $(PWD)/trusted-firmware-a/build/rk3568/release/bl31/bl31.elf 
export ROCKCHIP_TPL ?= $(PWD)/rockchip-images/rk3566_ddr_1056MHz_v1.23.bin 
#
# CROSS_COMPILE ?= $(HOME)/bin/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
export CROSS_COMPILE ?= aarch64-none-linux-gnu-

BUILD_DIR ?= build

help:
	$(info -)
	$(info Put the cross compiler on your path: aarch64-none-linux-gnu-)
	$(info -)
	$(info You can set the build dir like this: )
	$(info     make BUILD_DIR=test1 u-boot)
	$(info -)

# Build u-boot
.PHONY: u-boot
u-boot:
	rm -rf $(BUILD_DIR)/u-boot
	mkdir -p $(BUILD_DIR)/u-boot
	cd u-boot && make distclean
	cd u-boot && make O=../$(BUILD_DIR)/u-boot radxa-zero-3-rk3566_defconfig
	cd u-boot && make O=../$(BUILD_DIR)/u-boot 

# alias
.PHONY: uboot
uboot: u-boot
