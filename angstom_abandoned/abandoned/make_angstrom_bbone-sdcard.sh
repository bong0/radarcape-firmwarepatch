#!/bin/sh
# turn on debug mode
set -x
# set -e

echo "Please enter your desired hostname. Mostly this is present on a sticker on your Radarcape."
echo "For example, rc11"
read MY_HOSTNAME

# checks for required tools
reqs_passed=1
which mke2fs >/dev/null
if [ $? -ne 0 ]; then echo "Please install mke2fs (e2fsprogs)";reqs_passed=0; fi
which mkfs.ext4 >/dev/null
if [ $? -ne 0 ]; then echo "Please install mkfs.ext4";reqs_passed=0; fi
which mkfs.vfat >/dev/null
if [ $? -ne 0 ]; then echo "Please install mkfs.vfat (dosfstools)";reqs_passed=0; fi
which xz >/dev/null
if [ $? -ne 0 ]; then echo "Please install xz";reqs_passed=0; fi
which bc >/dev/null
if [ $? -ne 0 ]; then echo "Please install bc";reqs_passed=0; fi
which sfdisk >/dev/null
if [ $? -ne 0 ]; then echo "Please install sfdisk";reqs_passed=0; fi
which fdisk >/dev/null
if [ $? -ne 0 ]; then echo "Please install fdisk";reqs_passed=0; fi
which awk >/dev/null
if [ $? -ne 0 ]; then echo "Please install awk";reqs_passed=0; fi

if [ $reqs_passed -ne 1 ]; then exit 1; fi

if [ ! -f format_imagefile.sh ];
	echo "Cannot find format_imagefile.sh"
	exit 1
fi 
sh ./format_imagefile.sh /var/cache/angstrom-image.img

mkdir /tmp/${DRIVE_P}1
mkdir /tmp/${DRIVE_P}2

mount /dev/${DRIVE_P}1 /tmp/${DRIVE_P}1
mount /dev/${DRIVE_P}2 /tmp/${DRIVE_P}2

wget http://www.modesbeast.com/resources/MLO-beaglebone-2013.04-2013.05.20 \
-O /tmp/${DRIVE_P}1/MLO

wget http://www.modesbeast.com/resources/u-boot-beaglebone-2013.04-dirty.img \
-O /tmp/${DRIVE_P}1/u-boot.img

rm -f /tmp/rootfs.tar.xz
wget http://downloads.angstrom-distribution.org/demo/beaglebone/Angstrom-systemd-image-eglibc-ipk-v2012.12-beaglebone-2013.09.12.rootfs.tar.xz \
-O /tmp/rootfs.tar.xz
xz -d /tmp/rootfs.tar.xz
tar xf /tmp/rootfs.tar -C /tmp/${DRIVE_P}2

echo "The new SD card will be accessible via network with the hostname ${MY_HOSTNAME}"
echo $MY_HOSTNAME > /tmp/${DRIVE_P}2/etc/hostname

umount /dev/${DRIVE_P}1
umount /dev/${DRIVE_P}2
