#!/bin/sh

# Format an SD card for use on a BeagleBone / CALC
#
# Assumes erase block size is a multiple of 1.5, 2, 3, 4, 6, or 8 MiB.  For
# other sizes, adjustment of this script will be required.
#
# Resulting partition map will look like:
# mmcblk0p1 "u-boot" start @ 24 MiB, size = 24 MiB, FAT
# mmcblk0p2 "rootfs" start @ 48 MiB, size = rest, ext4

DRIVE=$1
ERASE=$2

if [ ! -b "$DRIVE" ] ; then
	echo Couldn\'t find ${DRIVE}. You must specify a valid block device.
	exit
fi

if [ "$DRIVE" = "/dev/sda" ] ; then
	echo You probably don\'t want to use /dev/sda...
	exit
fi

if echo ${DRIVE} | grep "mmcblk" ; then
	DRIVE_P="${DRIVE}p"
elif echo ${DRIVE} | grep "sd" ; then
	DRIVE_P="${DRIVE}"
else
	echo Invalid destination, must be either an mmcblkX or sdX device.
	exit
fi

dd if=/dev/zero of=$DRIVE bs=1024 count=1024
SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`
echo DISK SIZE - $SIZE bytes
# Each cylinder is 0.5 MiB
#CYLINDERS=`echo $SIZE/32/32/512 | bc`
CYLINDERS=`echo $SIZE/255/63/512 | bc`

echo CYLINDERS - $CYLINDERS

#sfdisk -D -H 32 -S 32 -C $CYLINDERS $DRIVE <<EOF

sfdisk -D -H 255 -S 63 -C $CYLINDERS --in-order --Linux --unit M $DRIVE <<EOF
1,48,0xE,*
,,,-

EOF
#kpartx -av $DRIVE # update partition devices in /dev
#partprobe -s $DRIVE
#hdparm -z $DRIVE
#sync

#48,48,0x0C,*
#96,,,-
#EOF


if [[ $ERASE != "ERASE" ]]; then
	echo "NOTICE: Skipping erase since you did not request it (second parameter was not 'ERASE')"
	exit 0
fi

if [ -f /dev/mapper/$(basename $DRIVE)1 ]; then
	dmsetup remove /dev/mapper/$(basename $DRIVE)1
fi;
if [ -f /dev/mapper/$(basename $DRIVE)2 ]; then
        dmsetup remove /dev/mapper/$(basename $DRIVE)2
fi;


mkfs.vfat -F 16 -n "U-BOOT" ${DRIVE_P}1

tempmount=$(mktemp -d)
mount ${DRIVE_P}2 $tempmount 2>&1 >/dev/null 

if [ $? -eq 0 ]; then
	echo "Found root partition already formatted. Just erasing its contents..."
	cd $tempmount
	# sanity check
	echo $tempmount | grep -o 'tmp' >/dev/null
	if [ $? -ne 0 ]; then
		echo "This looks suspicious. The generated tempfolder for mounting should contain the word 'tmp' at least... Quitting."
		exit 1
	fi
	rm -rf $tempmount/*
	cd ..
	umount $tempmount
else 
	mkfs.ext4 -L "rootfs" ${DRIVE_P}2
fi
rmdir $tempmount
