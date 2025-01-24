#!/usr/bin/env bash
# Script to format and partition an SD card to prepare for mp1-boot and an app

if [ $# -lt 2 ]; then
	read -p "What is the disk device to format (e.g. /dev/disk4): " DISK
	read -p "What is the disk partition stem (e.g. /dev/disk4s): " DISKSTEM
else
	DISK=$1
	DISKSTEM=$2
fi

if [ ! -b $DISK ]; then
	echo "Error: Device $DISK does not exist";
	exit 1;
fi

if [[ "$DISKSTEM" != *"$DISK"* ]]; then
	echo "Error: Disk device name $DISK must be a substring of the disk partition stem $DISKSTEM";
	exit 1;
fi

echo ""
echo "Device $DISK found"

echo ""
case "$(uname -s)" in
	Darwin)
		echo "Formatting"
		set -x
		diskutil eraseDisk FAT32 TMPDISK $DISK
		set +x
		;;
	*)
		;;
esac

echo ""
echo "Clearing partition table and converting MBR to GPT if present..."
echo ""

set -x
sudo sgdisk -go $DISK || exit
set +x

echo ""
echo "Partitioning..."
set -x
sudo sgdisk --resize-table=128 -a 1 \
	-n 1:128:32767 -c 1:uboot \
	-n 2:32768:+64M -c 2:linimg \
	-N 3 -c 3:fatfs \
	-t 3:EBD0A0A2-B9E5-4433-87C0-68B6B72699C7 \
	-p $DISK || exit
set +x

echo ""
echo "Formatting partition 2 as FAT32"

echo ""
case "$(uname -s)" in
	Darwin)
		set -x
		diskutil eraseVolume FAT32 LINIMG ${DISKSTEM}2 || exit
		# diskutil eraseVolume FAT32 FILESYS ${DISKSTEM}3 || exit
		sleep 1
		echo "Unmounting so macOS sees the new partitions"
		diskutil unmountDisk $DISK || exit
		set +x
		;;
	Linux)
		read -p "You must eject and re-insert the SD Card now. Press enter when ready." READY
		set -x
		sudo umount ${DISKSTEM}2
		sudo umount ${DISKSTEM}3
		sudo mkfs.fat -F 32 -n LINIMG ${DISKSTEM}2 || exit
		# sudo mkfs.fat -F 32 -n FILESYS ${DISKSTEM}3 || exit
		set +x
		;;
	*)
		echo 'OS not supported: please format $DISK partition 3 as FAT32'
		;;
esac

echo "Success!"

