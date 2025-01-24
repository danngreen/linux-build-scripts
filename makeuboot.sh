export BL31=${PWD}/trusted-firmware-a/build/rk3568/release/bl31/bl31.elf 
# export BL31=${PWD}/rockchip-images/rk3568_bl31_v1.44.elf
export ROCKCHIP_TPL=${PWD}/rockchip-images/rk3566_ddr_1056MHz_v1.23.bin 
export CROSS_COMPILE=~/bin/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
cd u-boot
make radxa-zero-3-rk3566_defconfig
make 
cd $O
