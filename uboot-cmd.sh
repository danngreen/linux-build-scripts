cd u-boot
export BL31=/home/dann/4ms/ca64/simple/trusted-firmware-a/build/rk3568/release/bl31/bl31.elf 
export ROCKCHIP_TPL=/home/dann/4ms/ca64/rkbin/bin/rk35/rk3566_ddr_1056MHz_v1.23.bin 
mkdir ../u-boot-build-1
make O=../u-boot-build-1 radxa-zero-3-rk3566_defconfig
make O=../u-boot-build-1

