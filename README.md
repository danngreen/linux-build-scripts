## Linux Build Scripts

This is a simple Makefile for building Linux, bootloaders, and root filesystem
(using buildroot) for an embedded device. Currently we are targetting the Radxa
CM3 + IO board (Rockchip RK3566).

The build is meant to be as simple as possible without extra menus/configs. The
Makefile is simple and does not do anything smart.

The Dockerfile defines a container which should be used for reproducible
builds.

## Setup 

You must build the docker container image first. You only have to do this once
on your host machine. If you change anything in the Dockerfile, then just
re-run this command to rebuild the container image.

```bash
docker build -t linuxbuilder .
```

Once that's built on your machine, enter it interactively:

```bash
./startdocker.sh

# This just runs:
# docker run --mount type=bind,src=.,dst=/project -it linuxbuilder:latest
```

Note that the current dir is bound to the docker's /project/ dir. So changes to
this dir in the docker container will show up in your host filesystem.

## Building

From within the docker container:

```bash
make all

# Or you can run each stage separately
make tfa
make u-boot
make linux
make linux-modules
make fs
```

You can clean any build with:

```bash
make clean-tfa
make clean-u-boot
make clean-linux
make clean-fs

make clean   # cleans all
```

For automated builds, you can just run have the docker container run `make all` non-interactively.

## Flashing to SD Card

The images will be in `build/` by default (You can specify another dir with `make BUILD_DIR=anotherdir all`)

To flash images to an SD Card, you will need to first format and partition the card. There's a simple script that helps with this:

```bash
./format-partition-sdcard.sh
```

It will ask you for the device, (e.g. /dev/sda). It will also ask you for the
device partition stem, often this is the same (e.g. /dev/sda).


It will partition the card as follows:
 - Partition 1: 16MB, raw data, for u-boot image (which includes tfa and ddr-init)
 - Partition 2: 64M, fatfs format, to hold the Linux kernel image and device tree blob
 - Partition 3: Remaining space for the ext2 root filesystem

There is 32k of empty space at the start (not in a partition), which presumably
holds some GPT headers. The bootloader binaries are loaded immediately after this offset,
which where the rk3566 BOOTROM will look for the first bootloader.

The second partition is FatFs, for interoperability with macOS, but you can
change that (you'll need to change the u-boot boot command as well).

To flash:

```bash

# Specify the mount point for your SD Card's Linux Image partition (part#2):
export SDCARD_LINUX_IMG_VOL=/tmp/mount

# Specify the sd card device and device partition stem (on Linux they are usually the same),
# on macOS it might be /dev/disk4 and /dev/disk4s, for example.
export SDCARD_DISK=/dev/sdX
export SDCARD_DISKP=/dev/sdX

# Specify the .dtb file (default is rk3566-radxa-cm3-io.dtb as built in linux/)
export LINUX_DTB=path/to/mydevicetreefile.dtb

# Flash the card:
make flash-sd

# Or run each step separately (make flash-sd just does these three:)
make flash-u-boot
make flash-linux
make flash-rootfs

```

The flashing commands use `sudo dd` so please make sure the device is set correctly!

## Booting

Insert the SD Card into the board and power on.

U-boot will fail the first time because we haven't specifed the bootcmd.

At the u-boot prompt, do this:

```
setenv bootcmd "fatload mmc 1:2 0x0a100000 mydevicetreefile.dtb; fatload mmc 1:2 0x02080000 Image; booti 0x02080000 - 0x0a100000"
setenv bootargs "root=/dev/mmcblk1p3 earlyprintk rw rootwait"
saveenv
boot
```

The next time you boot, it will automatically go into Linux.

The bootcmd loads the device tree file by name, so change `mydevicetreefile.dtb`
to the name of your dtb file. It loads this file and the linux `Image` file from
the mmc device 1, partition 2. On the CM3+IO board, device 1 is the SD Card 
and partition 2 is the FatFs partition setup by the format-partition-sdcard.sh script.
Adjust this if your Image and dtb are elsewhere. E.g. device 0 is the MMC (I think?), 
and/or it might be handy to put the Image and dtb on the rootfs partition
(partition 3). Keep in mind if you are loading from FatFs, then use `fatload`,
but use `ext2load` to load from ext2.

In bootargs, the rootfs is specified with mmcblk1p3. This means mmc device 1,
partition 3 (which is the SD Card, on the partition the script setup for the
rootfs ext2). Adjust this if you are booting from somewhere else or the rootfs
is different.

I don't know where the addresses in the bootcmd come from. TODO!

## Re-configuring
To re-configure or customize, the general process is to modify the files in `configs/`.
  - U-boot:
      ```
      cd u-boot
      make O=../build/u-boot menuconfig
      make O=../build/u-boot savedefconfig
      ```
      Do a diff on the defconfig in the u-boot tree vs. the original, and then
      add/change `configs/u-boot.cfg` file. Revert the defconfig file back.

  - Busybox:
      Add/change the busybox.fragment file manually (not sure how to discover these configs?)

  - Buildroot (fs):
      ```
      cd buildroot
      make O=../build/fs menuconfig
      make O=../build/fs savedefconfig
      ```
      The defconfig file is in configs/, so just commit it and that's it.

  - Linux kernel:
      Not sure how to do this yet. 
      Currently we are using the default defconfig for arch64 (there is a generic_defconfig in configs/ but it's not used)
      Maybe use `linux/scripts/diffconfig`?

  - Linux kernel modules:
      Not sure how to do this yet.

  - Linux DTB:
      Not sure how to do this yet. Overlays?


## TODO:

- Integrate our own device tree without a fork of the linux source.

- Manage modifications to kernel modules.

